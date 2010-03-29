/*
 * This file is part of the PyGoWave ActionScript Client API
 *
 * Copyright (C) 2009 Patrick Schneider <patrick.p2k.schneider@googlemail.com>
 * Copyright (C) 2010 Markus Strickler <markus.strickler at googlemail dot com>
 *
 * This library is free software: you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; see the file
 * COPYING.LESSER. If not, see <http://www.gnu.org/licenses/>.
 */
package pygowave.controller
{
	import com.adobe.serialization.json.JSON;
	import com.adobe.utils.ArrayUtil;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.utils.UIDUtil;
	
	import org.codehaus.stomp.Stomp;
	import org.codehaus.stomp.event.ConnectedEvent;
	import org.codehaus.stomp.event.MessageEvent;
	import org.codehaus.stomp.event.ReconnectFailedEvent;
	import org.codehaus.stomp.event.STOMPErrorEvent;
	import org.codehaus.stomp.headers.ConnectHeaders;
	import org.codehaus.stomp.headers.SendHeaders;
	import org.codehaus.stomp.headers.SubscribeHeaders;
	import org.codehaus.stomp.headers.UnsubscribeHeaders;
	
	import pygowave.event.OperationsEvent;
	import pygowave.event.PygowaveEvent;
	import pygowave.model.Blip;
	import pygowave.model.IParticipantProvider;
	import pygowave.model.Participant;
	import pygowave.model.WaveModel;
	import pygowave.model.Wavelet;
	import pygowave.operations.OpManager;
	import pygowave.operations.Operation;

	public class Controller extends EventDispatcher implements IParticipantProvider
	{
		[Bindable]
		public var state:String = 'disconnected';
		
		public var stompServer:String = "localhost";
		public var stompPort:int = 61613;
		public var stompUsername:String = "pygowave_client";
		public var stompPassword:String = "pygowave_client";
		
		public var conn:Stomp = new Stomp();
		
		private var pingTimer:Timer = new Timer(20000);
		private var pendingTimer:Timer = new Timer(10000);
		
		private var lastSearchId:int = 0;
		private var participantsTodoCollect:Boolean = false;
		private var participantsTodo:Array = new Array();
		private var allParticipants:Dictionary = new Dictionary();
		
		private var username:String;
		private var password:String;
		
		public var openWavelets:ArrayCollection = new ArrayCollection();
		public var allWaves:Dictionary = new Dictionary();
		public var allWavelets:Dictionary = new Dictionary();
		
		[Bindable]
		public var allWaveletColl:ArrayCollection = new ArrayCollection();
		
		public var mCached:Dictionary = new Dictionary();
		public var mPending:Dictionary = new Dictionary();
		public var ispending:Dictionary = new Dictionary();
		private var createdWaveId:String = null;
		private var draftblips:Dictionary = new Dictionary();
		public var viewerId:String = '';
		public var waveAccessKeyRx:String = '';
		public var waveAccessKeyTx:String = '';
		
		public function Controller()
		{
			this.username = '';
			this.password = '';
			this.conn.addEventListener(ConnectedEvent.CONNECTED, conn_socketConnected);
			this.conn.addEventListener(MessageEvent.MESSAGE, conn_messageReceived);
			this.conn.addEventListener(STOMPErrorEvent.ERROR, conn_socketError);
			this.conn.addEventListener(IOErrorEvent.IO_ERROR, conn_ioError);
			this.conn.addEventListener(ReconnectFailedEvent.RECONNECT_FAILED, conn_reconectFailed);
			this.pingTimer.addEventListener(TimerEvent.TIMER, pingTimer_timeout);
			this.pendingTimer.addEventListener(TimerEvent.TIMER, pendingTimer_timeout);
			
		}

		public function connectToHost(stompServer:String, username:String, password:String, stompPort:int=61613, stompUsername:String="pygowave_client", stompPassword:String="pygowave_client"):void
		{
			this.stompServer = stompServer;
			this.stompPort = stompPort;
			this.stompUsername = stompUsername;
			this.stompPassword = stompPassword;
			this.reconnectToHost(username, password);
		}

		public function reconnectToHost(username:String, password:String):void
		{
			this.username = username;
			this.password = password;
			var ch:ConnectHeaders = new ConnectHeaders();
			ch.login = this.stompUsername;
			ch.passcode = this.stompPassword;
			this.conn.autoReconnect = false;
			this.state = 'connecting';
			this.conn.connect(this.stompServer, this.stompPort, ch);
		}
		
		public function disconnectFromHost():void
		{
			// TODO check connection state
			for each (var id:String in this.openWavelets)
			{
				this.unsubscribeWavelet(id);
			}
			this.sendJson("manager", "DISCONNECT", new Object());
			this.conn.autoReconnect = false;
			this.pingTimer.stop();
			this.pendingTimer.stop();			
			this.conn.disconnect();
			this.allWaves = new Dictionary();
			this.allWavelets = new Dictionary();
			this.allWaveletColl.removeAll();
			this.openWavelets.removeAll();
			this.state = 'disconnected';
		}
		
		public function get hostName():String
		{
			return this.stompServer;
		}
		
		private function addWave(wave:WaveModel, initial:Boolean):void
		{
			// Q_ASSERT(!this->m_allWaves.contains(wave->id()));
			this.allWaves[wave.waveId] = wave;
			
			for each (var wavelet:Wavelet in wave.wavelets) {
				this.allWavelets[wavelet.id] = wavelet;
				this.allWaveletColl.addItem(wavelet);
				var mcached:OpManager = new OpManager(wavelet.wave.waveId, wavelet.id, this.viewerId);
				mcached.addEventListener(OperationsEvent.AFTER_OPERATIONS_INSERTED, mcached_afterOperationsInserted);
				wavelet.addEventListener('participantsChanged', wavelet_participantsChanged);
				this.mCached[wavelet.id] = mcached;
				this.mPending[wavelet.id] = new OpManager(wavelet.wave.waveId, wavelet.id, this.viewerId);
				this.ispending[wavelet.id] = false;
			}
//			var created:Boolean = false;
//			if (this.createdWaveId == wave->id()) {
//				this->m_createdWaveId.clear();
//				created = true;
//			}
//			emit q->waveAdded(wave->id(), created, initial);
		}
		
		private function removeWave(id:String, deleteObject:Boolean):void
		{
			// Q_ASSERT(this->m_allWaves.contains(id));
			// emit q->waveAboutToBeRemoved(id);
			var wave:WaveModel = this.allWaves[id];
			for each (var wavelet:Wavelet in wave.wavelets) {
				delete this.allWavelets[wavelet.id];
				var index:int = this.allWaveletColl.getItemIndex(wave);
				this.allWaveletColl.removeItemAt(index);
			}
//			if (deleteObject)
//				wave.deleteLater();
		}
		
		private function clearWaves(deleteObjects:Boolean):void
		{
			for (var id:String in this.allWaves)
				this.removeWave(id, deleteObjects);
		}		

		private function conn_socketConnected(event:Event):void
		{
			trace("Controller: Logging into message broker...");
			this.state = 'connected';
			// TODO emit q->stateChanged(Controller::ClientConnected);
			//this->conn->login(this->m_stompUsername, this->m_stompPassword);
			trace("Controller: Authenticating...");
			this.waveAccessKeyRx = UIDUtil.createUID();
			this.waveAccessKeyTx = this.waveAccessKeyRx;
			
			this.subscribeWavelet('login', false);
			
			var prop:Object = new Object();
			prop.username = this.username;
			prop.password = this.password;
			this.password = ''; // Delete Password after use
			this.sendJson('login', 'LOGIN', prop);			
		}
		
//		void ControllerPrivate::_q_conn_socketDisconnected()
//		{
//			P_Q(Controller);
//			qDebug("Controller: Disconnected...");
//			this->pingTimer->stop();
//			this->m_state = Controller::ClientDisconnected;
//			this->clearWaves(true);
//			emit q->stateChanged(Controller::ClientDisconnected);
//		}
		
		private function conn_messageReceived(event:MessageEvent):void
		{
			var msgs:Array;
			trace('Message received: ' + event.message);
			if (this.state == 'connected')
			{
				msgs = JSON.decode(event.message.body.toString());	
				if (msgs.length != 1) {
					trace("Controller: Login reply must contain a single message!"); 
					return;
				}
				
				var msg:Object = msgs[0];
				if (msg.type && msg.property) {
					var type:String = msg.type;
					if (type == 'ERROR') {
//						var prop:Object = msg.property;
						// emit q->errorOccurred("login", prop["tag"].toString(), prop["desc"].toString());
						return;
					}
					if (type != 'LOGIN') {
						trace("Controller: Login reply must be a 'LOGIN' message!");
						return;
					}
					var prop:Object = msg.property;
					if (prop.rx_key && prop.tx_key && prop.viewer_id) {
						this.unsubscribeWavelet('login', false);
						this.waveAccessKeyRx = prop.rx_key;
						this.waveAccessKeyTx = prop.tx_key;
						this.viewerId = prop.viewer_id;
						this.subscribeWavelet('manager', false);
						this.pingTimer.start();
						this.state = 'online';
						// qDebug("Controller: Online! Keys: %s/rx %s/tx", this->m_waveAccessKeyRx.constData(), this->m_waveAccessKeyTx.constData());
						// emit q->stateChanged(Controller::ClientOnline);
						
						this.sendJson('manager', 'WAVE_LIST');
					}
					else {
						trace("Controller: Login reply must contain the properties 'rx_key', 'tx_key' and 'viewer_id'!");
						return;
					}
				}
				else {
					trace("Controller: Message lacks 'type' and 'property' field!");
					return;
				}
			}
			else if (this.state == 'online')
			{
				///qDebug("Controller: Received on %s:\n%s", frame.destination().constData(), qPrintable(frame.body()));
				var destination:String = event.message.headers.destination as String;
				var routing_key:Array = destination.split('.');
				if (routing_key.length != 3 || routing_key[2] != 'waveop') {
					// qWarning("Controller: Malformed routing key '%s'!", frame.destination().constData());
					return;
				}
				var waveletId:String = routing_key[1];
				msgs = JSON.decode(event.message.body.toString());	
				for each (var m:Object in msgs) {
					if (m.type) { 
						if (m.property != null)
							this.processMessage(waveletId, m.type.toString(), m.property);
						else
							this.processMessage(waveletId, m.type.toString());
					}
					else {
						trace("Controller: Message lacks 'type' field!");
						return;
					}
				}
			}
		}
		
//		public function conn_socketStateChanged(state):void
//		{
//			qDebug("Controller: Socket state: %d", state);
//			if (state == QAbstractSocket::UnconnectedState && this->m_state == Controller::ClientDisconnected)
//				this->_q_conn_socketDisconnected();
//		}
		
		public function conn_socketError(event:STOMPErrorEvent):void
		{
//			if (event.type == STOMPErrorEvent.)
//				return;
//			P_Q(Controller);
//			QByteArray errTag = "SOCKET_ERROR_";
//			errTag.append(QByteArray::number((int) err));
//			q->errorOccurred("manager", errTag, this->conn->socketErrorString());
			trace("Error: " + event.error.body);				
		}

		public function conn_ioError(event:IOErrorEvent):void
		{
			trace("IOError: " + event.text);
			this.state = 'disconnected';
		}
		
		public function conn_reconectFailed(event:ReconnectFailedEvent):void
		{
			trace("ReconnectFailed.");
		}
		
		public function wave(id:String):WaveModel
		{
			if (this.allWaves.hasOwnProperty(id))
				return this.allWaves[id];
			else
				return null;
		}
		
		public function wavelet(id:String):Wavelet
		{
			if (this.allWavelets.hasOwnProperty(id))
				return this.allWavelets[id];
			else
				return null;
		}
		
		public function viewer():Participant
		{
			return this.participant(this.viewerId);
		}

		public function participant(id:String):Participant
		{
			if (!this.allParticipants.hasOwnProperty(id)) {
				this.allParticipants[id] = new Participant(id);
				if (this.participantsTodoCollect)
					this.participantsTodo.push(id);
				else
					this.retrieveParticipant(id);
			}
			return this.allParticipants[id];
		}
		
		public function openWavelet(waveletId:String):void
		{
			this.subscribeWavelet(waveletId);
		}
		
		public function closeWavelet(waveletId:String):void
		{
			this.unsubscribeWavelet(waveletId);
		}
		
		private function pingTimer_timeout(event:Event):void
		{
			this.sendJson("manager", "PING", new Date().time);
		}
		
		private function sendJson(dest:String, type:String, property:Object=null):void
		{
			if (this.waveAccessKeyTx == null || this.waveAccessKeyTx == '')
				return;
			var obj:Object = new Object();
			obj["type"] = type;
			if (property != null)
				obj["property"] = property;

			var sh: SendHeaders = new SendHeaders();
			var destination:String = this.waveAccessKeyTx + "." + dest + ".clientop";
			sh.addHeader('exchange', 'wavelet.topic');
			sh.addHeader('routing_key', destination);
			sh.addHeader('content-type', 'application/json');
			sh.addHeader('content-encoding', 'utf-8');
			var message:String = JSON.encode(obj);
			trace('Sending message: ' + message);
			///if (dest != "login") qDebug("Controller: Sending to %s:\n%s", frame.destination().constData(), qPrintable(frame.body()));
			this.conn.sendTextMessage(destination, message, sh);
			if (this.state == 'online') {
				this.pingTimer.stop();
				this.pingTimer.start();
			}
		}
		
		private function subscribeWavelet(id:String, open:Boolean=true):void
		{
			var sh:SubscribeHeaders = new SubscribeHeaders();
			var destination:String = this.waveAccessKeyRx + "." + id + ".waveop";
			sh.ack = 'auto';
			sh.amqExclusive = 'true';
			sh.addHeader('routing_key', destination);
			sh.addHeader('exchange', 'wavelet.direct');
			
			this.conn.subscribe(destination, sh);
			
			if (open)
				this.sendJson(id, 'WAVELET_OPEN', new Object());
		}		

		private function unsubscribeWavelet(id:String, close:Boolean=true):void
		{
			if (close)
				this.sendJson(id, "WAVELET_CLOSE", new Object());
			var uh:UnsubscribeHeaders = new UnsubscribeHeaders();
			var destination:String = this.waveAccessKeyRx + "." + id + ".waveop";
			uh.destination = destination;
			uh.addHeader('routing_key', destination);
			uh.addHeader('exchange', 'wavelet.direct');
			
			this.conn.unsubscribe(destination, uh);
			var index:int = this.openWavelets.getItemIndex(id);
			if (index >= 0)
				this.openWavelets.removeItemAt(index);
		}
		
		public function addParticipant(waveletId:String, id:String):void
		{
			if (this.allWavelets.hasOwnProperty(waveletId))
				return;
			Wavelet(this.mCached[waveletId]).addParticipant(this.participant(id));
			this.allWavelets[waveletId].addParticipant(this.participant(id));
		}
		
		public function createNewWave(title:String):void
		{
			this.createNewWavelet('', title);
		}
		
		public function createNewWavelet(waveId:String, title:String):void
		{
			var prop:Object = new Object();
			prop.waveId = waveId;
			prop.title = title;
			this.sendJson('manager', 'WAVELET_CREATE', prop);
		}
		
		public function leaveWavelet(waveletId:String):void
		{
			if (!this.allWavelets.hasOwnProperty(waveletId))
				return;
			this.mCached[waveletId].waveletRemoveParticipant(this.viewerId);
			this.allWavelets[waveletId].removeParticipant(this.viewerId);
		}		
		
		public function refreshGadgetList(forced:Boolean):void
		{
//			if (this.cachedGadgetList.isEmpty() || forced)
//				d->sendJson("manager", "GADGET_LIST");
//			else
//				emit updateGadgetList(d->m_cachedGadgetList);
		}
		
		public function newWaveletByDict(wave:WaveModel, waveletId:String, waveletDict:Object):Wavelet
		{
			var participants:Array = new Array();
			var part_id:String;
			for (part_id in waveletDict["participants"])
				participants.push(part_id);
			
			var wavelet:Wavelet = wave.createWavelet(
				waveletId,
				this.participant(waveletDict["creator"]),
				waveletDict["title"],
				waveletDict["isRoot"],
				new Date(waveletDict["creationTime"]),
				new Date(waveletDict["lastModifiedTime"]),
				waveletDict["version"]
			);
			
			for (part_id in participants)
				wavelet.addParticipant(this.participant(part_id));
			
			return wavelet;
		}
		
		public function updateWaveletByDict(wavelet:Wavelet, waveletDict:Object):void
		{
			var participants:Array = new Array();
			for (var part_id:String in waveletDict["participants"])
				participants.push(part_id);
			
			wavelet.title = waveletDict["title"];
			wavelet.lastModified = waveletDict["lastModifiedTime"];
			
			var newParticipants:Array = participants.slice();
			var oldParticipants:Array = wavelet.allParticipantIDs().source.slice();
			var pId:String;
			for (pId in oldParticipants)
				delete newParticipants[pId];
			for (pId in participants)
				delete oldParticipants[pId];
			
			var id:String;
			for (id in newParticipants)
				wavelet.addParticipant(this.participant(id));
			for (id in oldParticipants)
				wavelet.removeParticipant(id);
		}
		
		private function collectParticipants():void
		{
			this.participantsTodoCollect = true;
		}		
		
		private function retrieveParticipants():void
		{
			// Retrieve missing participants
			if (this.participantsTodo.length > 0) {
				var l:Array = new Array();
				for (var id:String in this.participantsTodo)
					l.push(id);
				this.sendJson("manager", "PARTICIPANT_INFO", l);
				this.participantsTodo = new Array();
			}
			this.participantsTodoCollect = false;
		}		
				
		private function retrieveParticipant(id:String):void
		{
			this.sendJson("manager", "PARTICIPANT_INFO", new Array(id));
		}		
		
		private function processMessage(waveletId:String, type:String, property:Object=null):void
		{
			var waveId:String;
			var wave:WaveModel;
			var wavelets:Object;
			var wavelet:Wavelet;
			var s_waveletId:String;
			var id:String;
			var pid:String;
			var prop:Object;
			
			if (type == 'ERROR') {
				// TODO emit q->errorOccurred(waveletId, propertyMap["tag"].toString(), propertyMap["desc"].toString());
				return;
			}
			// Manager messages
			if (waveletId == 'manager') {
				if (type == 'WAVE_LIST') {
					this.clearWaves(true); // Clear all; this message is only received once per connection
					this.collectParticipants();
					for (var s_waveId:String in property) {
						waveId = s_waveId;
						wave = new WaveModel(waveId, this.viewerId, this);
						wavelets = property[s_waveId];
						for (s_waveletId in wavelets)
							this.newWaveletByDict(wave, s_waveletId, wavelets[s_waveletId]);
						this.addWave(wave, true);
					}
					this.retrieveParticipants();
				}
				else if (type == 'WAVELET_LIST') {
					waveId = property["waveId"];
					if (!this.allWaves.hasOwnProperty(waveId)) { // New wave
						wave = new WaveModel(waveId, this.viewerId, this);
						wavelets = property["wavelets"];
						this.collectParticipants();
						for (s_waveletId in wavelets)
							this.newWaveletByDict(wave, s_waveletId, wavelets[s_waveletId]);
						this.addWave(wave, false);
						this.retrieveParticipants();
					}
					else { // Update old
						wave = this.allWaves[waveId];
						wavelets = property["wavelets"];
						for (s_waveletId in wavelets) {
							var waveletId:String = s_waveletId;
							wavelet = wave.wavelets[waveletId];
							this.collectParticipants();
							if (wavelet != null)
								this.updateWaveletByDict(wavelet, wavelets[s_waveletId]);
							else
								this.newWaveletByDict(wave, waveletId, wavelets[s_waveletId]);
							this.retrieveParticipants();
						}
					}
				}
				else if (type == 'PARTICIPANT_INFO') {
					this.collectParticipants();
					for (var s_id:String in property) {
						id = s_id;
						// TODO this.participant(id).updateData(propertyMap[s_id].toMap(), this->m_stompServer);
					}
					this.participantsTodo = new Array(); // Trash
					this.retrieveParticipants();
				}
				else if (type == 'PONG') {
					trace('PONG');
//					quint64 ts = this->timestamp();
//					quint64 sentTs = property.toULongLong();
//					if (sentTs != 0 && sentTs < ts)
//						qDebug("Controller: Latency is %llums", ts - sentTs);
				}
				else if (type == 'PARTICIPANT_SEARCH') {
					if (property["result"] == 'OK') {
						var ids:Array = new Array();
						this.collectParticipants();
						for (id in property["data"]) {
							this.participant(id);
							ids.push(id);
						}
						this.retrieveParticipants();
						// TODO emit q->participantSearchResults(this->m_lastSearchId, ids);
					}
					else if (property["result"].toString() == 'TOO_SHORT')
						trace('TOO SHORT');
						// TODO emit q->participantSearchResultsInvalid(this->m_lastSearchId, propertyMap["data"].toInt());
				}
				else if (type == 'WAVELET_ADD_PARTICIPANT') {
					pid = property["id"];
					waveletId = property["waveletId"];
					wavelet = null;
					if (this.allWavelets.hasOwnProperty(waveletId))
						wavelet = this.allWavelets[waveletId];
					if (wavelet == null) {
						if (pid == this.viewerId) { // Someone added me to a new wave, joy!
							prop = new Object();
							prop["waveId"] = property["waveId"];
							this.sendJson("manager", "WAVELET_LIST", prop); // Get the details
						}
					}
					else
						wavelet.addParticipant(this.participant(pid));
				}
				else if (type == 'WAVELET_REMOVE_PARTICIPANT') {
					pid = property["id"];
					waveId = property["waveId"];
					waveletId = property["waveletId"];
					if (this.allWavelets.hasOwnProperty(waveletId))
						this.allWavelets[waveletId].removeParticipant(pid);
				}
				else if (type == 'WAVELET_CREATED') {
					waveId = property["waveId"];
					waveletId = property["waveletId"];
					if (!this.allWaves.hasOwnProperty(waveId))
						this.createdWaveId = waveId;
					prop = new Object();
					prop["waveId"] = property["waveId"];
					this.sendJson('manager', 'WAVELET_LIST', prop); // Reload wave
				}
				else if (type == 'GADGET_LIST') {
//					var propertyList:Array = property as Array;
//					this.cachedGadgetList = new Array();
//					foreach (QVariant var, propertyList) {
//						QVariantMap gadgetInfo = var.toMap();
//						QHash<QString,QString> gadgetInfoClean;
//						foreach (QString entry, gadgetInfo.keys())
//						gadgetInfoClean[entry] = gadgetInfo[entry].toString();
//						this->m_cachedGadgetList.append(gadgetInfoClean);
//					}
//					emit q->updateGadgetList(this->m_cachedGadgetList);
				}
				return;
			}
			// Wavelet messages
//			Q_ASSERT(this->m_allWavelets.contains(waveletId));
			wavelet = this.allWavelets[waveletId];
			if (wavelet != null) {
				if (type == 'WAVELET_OPEN') {
					var blips:Object = property["blips"];
					var waveletMap:Object = property["wavelet"];
					var rootBlipId:String = waveletMap["rootBlipId"];
					wavelet.loadBlipsFromSnapshot(blips, rootBlipId);
					this.openWavelets.addItem(wavelet.id);
					//TODO emit q->waveletOpened(wavelet->id(), wavelet->isRoot());
				}
				else if (type == "OPERATION_MESSAGE_BUNDLE") {
					this.queueMessageBundle(
						wavelet,
						false,
						new ArrayCollection(property["operations"]),
						property["version"],
						property["blipsums"],
						new Date(property["timestamp"]),
						property["contributor"]
					);
				}
				else if (type == "OPERATION_MESSAGE_BUNDLE_ACK") {
					this.queueMessageBundle(
						wavelet,
						true,
						property["newblips"],
						property["version"],
						property["blipsums"],
						new Date(property["timestamp"]),
						property["contributor"]
					);
				}
				else if (type == "GADGET_LIST") {
				}
			}
		}
		
		public function textInserted(waveletId:String, blipId:String, index:int, content:String):void
		{
//			Q_ASSERT(d->m_allWavelets.contains(waveletId));
			var w:Wavelet = this.allWavelets[waveletId];
			var b:Blip = w.blipById(blipId);// Q_ASSERT(b);
			this.mCached[waveletId].documentInsert(blipId, index, content);
			b.insertText(index, content, this.viewer(), true);
			b.lastModified = new Date();
		}
			
		public function textDeleted(waveletId:String, blipId:String, start:int, end:int):void
		{
//			Q_ASSERT(d->m_allWavelets.contains(waveletId));
			var w:Wavelet = this.allWavelets[waveletId];
			var b:Blip = w.blipById(blipId); // Q_ASSERT(b);
			this.mCached[waveletId].documentDelete(blipId, start, end);
			b.deleteText(start, end-start, this.viewer(), true);
			b.lastModified = new Date();
		}
			
		public function elementInsert(waveletId:String, blipId:String, index:int, type:String, properties:Object):void
		{
//			Q_ASSERT(d->m_allWavelets.contains(waveletId));
			var w:Wavelet = this.allWavelets[waveletId];
			var b:Blip = w.blipById(blipId);// Q_ASSERT(b);
			this.mCached[waveletId].documentElementInsert(blipId, index, type, properties);
			b.insertElement(index, type, properties, this.viewer(), false);
			b.lastModified = new Date();
		}
			
		public function elementDelete(waveletId:String, blipId:String, index:int):void
		{
//			Q_ASSERT(d->m_allWavelets.contains(waveletId));
			var w:Wavelet = this.allWavelets[waveletId];
			var b:Blip = w.blipById(blipId);// Q_ASSERT(b);
			this.mCached[waveletId].documentElementDelete(blipId, index);
			b.deleteElement(index, this.viewer(), true);
			b.lastModified = new Date();
		}
			
		public function elementDeltaSubmitted(waveletId:String, blipId:String, index:int, delta:Object):void
		{
//			Q_ASSERT(d->m_allWavelets.contains(waveletId));
			var w:Wavelet = this.allWavelets[waveletId];
			var b:Blip = w.blipById(blipId);// Q_ASSERT(b);
			this.mCached[waveletId].documentElementDelta(blipId, index, delta);
			b.applyElementDelta(index, delta, this.viewer());
			b.lastModified = new Date();
		}
			
		public function elementSetUserpref(waveletId:String, blipId:String, index:int, key:String, value:String):void
		{
//			Q_ASSERT(d->m_allWavelets.contains(waveletId));
			var w:Wavelet = this.allWavelets[waveletId];
			var b:Blip = w.blipById(blipId);// Q_ASSERT(b);
			this.mCached[waveletId].documentElementSetpref(blipId, index, key, value);
			b.setElementUserpref(index, key, value, this.viewer(), true);
			b.lastModified = new Date();
		}
			
		public function appendBlip(waveletId:String):void
		{
//			Q_ASSERT(d->m_allWavelets.contains(waveletId));
			var w:Wavelet = this.allWavelets[waveletId];
			var newBlip:Blip = w.appendBlip('', '', new ArrayCollection(), this.viewer(), new Dictionary(), false, new Date());
			this.mCached[waveletId].waveletAppendBlip(newBlip.id);
			this.mCached[waveletId].lockBlipOps(newBlip.id);
		}
			
		public function deleteBlip(waveletId:String, blipId:String):void
		{
//			Q_ASSERT(d->m_allWavelets.contains(waveletId));
			var w:Wavelet = this.allWavelets[waveletId];
			this.mCached[waveletId].blipDelete(blipId);
			if (this.draftblips.hasOwnProperty(waveletId))
			{
				var drafts:Array = this.draftblips[waveletId];
				if (drafts != null && ArrayUtil.arrayContainsValue(drafts, blipId))
				{
					ArrayUtil.removeValueFromArray(drafts, blipId);
				}					
			}
			w.deleteBlip(blipId);
		}
			
		public function draftBlip(waveletId:String, blipId:String, enabled:Boolean):void
		{
			if (this.draftblips[waveletId] == null)
				this.draftblips[waveletId] = new Array();
			
			var draftblips:Array = this.draftblips[waveletId];
			
			if ((!enabled) && (ArrayUtil.arrayContainsValue(draftblips, blipId))) {
				ArrayUtil.removeValueFromArray(draftblips, blipId);
				if (!(blipId.substr(0, 4) == 'TBD_')) {
					var mcached:OpManager = this.mCached[waveletId];
					mcached.unlockBlipOps(blipId);
					if (mcached.canFetch() && !this.hasPendingOperations(waveletId))
						this.transferOperations(waveletId);
				}
			}
			else if (enabled && !(ArrayUtil.arrayContainsValue(draftblips, blipId))) {
				draftblips.push(blipId);
				if (!(blipId.substr(0, 4) == 'TBD_'))
					this.mCached[waveletId].lockBlipOps(blipId);
			}
		}
			
		private function mcached_afterOperationsInserted(event:OperationsEvent):void
		{
			var mcached:OpManager = event.currentTarget as OpManager;
//			Q_ASSERT(mcached);
			var waveletId:String = mcached.waveletId;
			if (!this.hasPendingOperations(waveletId))
				this.transferOperations(waveletId);
		}
		
		private function wavelet_participantsChanged(event:PygowaveEvent):void
		{
			var wavelet:Wavelet = event.currentTarget as Wavelet;
//			Q_ASSERT(wavelet);
			if (!wavelet.participant(this.viewerId)) { // I got kicked
				var wave:WaveModel = wavelet.wave;
				var waveletId:String = wavelet.id;
				if (wavelet == wave.rootWavelet) // It was the root wavelet, oh no!
					this.removeWave(wave.waveId, true);
				else { // Some other wavelet I was on, phew...
					wave.removeWavelet(waveletId);
					delete this.allWavelets[waveletId];
					var index:int = this.allWaveletColl.getItemIndex(wavelet);
					this.allWaveletColl.removeItemAt(index);
				}
				// Wavelet has been closed implicitly
				delete this.openWavelets[waveletId];
			}
		}
		
		private function hasPendingOperations(waveletId:String):Boolean
		{
//			Q_ASSERT(this->ispending.contains(waveletId));
			return (this.ispending[waveletId]) || !(this.mPending[waveletId].isEmpty());
		}
			
		private function transferOperations(waveletId:String):void
		{
//			Q_ASSERT(this->mpending.contains(waveletId));
			var mp:OpManager = this.mPending[waveletId];
			var mc:OpManager = this.mCached[waveletId];
			var model:Wavelet = this.allWavelets[waveletId];
			
			if (mp.isEmpty())
				mp.put(mc.fetch());
			
			if (mp.isEmpty())
				return;
			
			//if (!this->isBlocked(waveletId)) {
			this.ispending[waveletId] = true;
			if (this.pendingTimer.running)
				this.pendingTimer.stop();
			this.pendingTimer.start();
			
			var bundle:Object = new Object();
			bundle["version"] = model.version;
			bundle["operations"] = mp.serialize();
			this.sendJson(waveletId, 'OPERATION_MESSAGE_BUNDLE', bundle);
			//}
		}
			
		public function searchForParticipant(text:String):int
		{
			this.sendJson('manager', 'PARTICIPANT_SEARCH', text);
			this.lastSearchId++;
			return this.lastSearchId;
		}
				
//		QList< QHash<QString,QString> > Controller::gadgetList()
//		{
//			P_D(Controller);
//			if (d->m_cachedGadgetList.isEmpty())
//				this->refreshGadgetList();
//			return d->m_cachedGadgetList;
//		}
		
		private function pendingTimer_timeout(event:Event):void
		{
			//TODO
		}
		
		private function queueMessageBundle(wavelet:Wavelet, ack:Boolean, serial_ops:Object, version:int, blipsums:Object, timestamp:Date, contributor:String):void
		{
			//TODO
			this.processMessageBundle(wavelet, ack, serial_ops, version, blipsums, timestamp, contributor);
		}
		
		private function processMessageBundle(wavelet:Wavelet, ack:Boolean, serial_ops:Object, version:int, blipsums:Object, timestamp:Date, contributor:String):void
		{
			var mpending:OpManager = this.mPending[wavelet.id];
			var mcached:OpManager = this.mCached[wavelet.id];
			var blipsums_prep:Dictionary;
			var key:String;
			
			if (!ack) {
				var delta:OpManager = new OpManager(wavelet.wave.waveId, wavelet.id, contributor);
				delta.unserialize(serial_ops as ArrayCollection);
				
				var ops:ArrayCollection = new ArrayCollection();
				
				// Iterate over all operations
				for each (var incoming:Operation in delta.operations) {
					// Transform pending operations, iterate over results
					for each (var tr:Operation in mpending.transform(incoming)) {
						// Transform cached operations, save results
						ops.addAll(mcached.transform(tr));
					}
				}
				
				// Apply operations
				this.collectParticipants();
				wavelet.applyOperations(ops, timestamp, contributor);
				this.retrieveParticipants();
				
				// Set version and checkup
				wavelet.version = version;
				if (!this.hasPendingOperations(wavelet.id) && mcached.isEmpty()) {
					blipsums_prep = new Dictionary();
					for (key in blipsums)
						blipsums_prep[key] = blipsums[key];
					wavelet.checkSync(blipsums_prep);
				}
			}
			else { // ACK message
				this.pendingTimer.stop();
				wavelet.version = version;
				mpending.fetch(); // Clear
				
				// Update Blip IDs
				var draftblips:Array = this.draftblips[wavelet.id];
				var idMap:Object = serial_ops;
				for (var s_tempId:String in idMap) {
					var tempId:String = s_tempId;
					var blipId:String = idMap[tempId];
					wavelet.updateBlipId(tempId, blipId);
					mcached.unlockBlipOps(tempId);
					mcached.updateBlipId(tempId, blipId);
					if ((draftblips != null) && (ArrayUtil.arrayContainsValue(draftblips, tempId))) {
						ArrayUtil.removeValueFromArray(draftblips, tempId);
						draftblips.push(blipId);
						mcached.lockBlipOps(blipId);
					}
				}
				
				if (!mcached.isEmpty()) {
					if (mcached.canFetch())
						this.transferOperations(wavelet.id); // Send cached
				}
				else {
					// All done, we can do a check-up
					blipsums_prep = new Dictionary();
					for (key in blipsums)
						blipsums_prep[key] = blipsums[key];
					wavelet.checkSync(blipsums_prep);
					this.ispending[wavelet.id] = false;
				}
			}
		}		
	}
}