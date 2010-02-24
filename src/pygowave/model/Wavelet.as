/*
 * This file is part of the PyGoWave ActionScript Client API
 *
 * Copyright (C) 2010 Markus Strickler <markus.strickler@googlemail.com>
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
package pygowave.model
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	
	import pygowave.event.PygowaveEvent;
	import pygowave.operations.Operation;
	
	/**
	 * \class PyGoWave::Wavelet
	 * \brief Models a Wavelet on a Wave.
	 *
	 * This class should not be instanitated directly. Please
	 * use \link WaveModel::createWavelet() \endlink.
	 */
	public class Wavelet extends EventDispatcher {
		public var wave:WaveModel;
		public var id:String;
		public var creator:Participant;
		private var _title:String;
		public var root:Boolean;
		public var created:Date;
		private var _lastModified:Date;
		public var version:int;
		public var rootBlip:Blip;
		private var _status:String;
		public var participants:Dictionary;
		public var blips:ArrayCollection;
		
		/**
		 * Creates a new Wavelet object.
		 *
		 * \a wave - Parent WaveModel object
		 *
		 * \a id - Wavelet ID
		 *
		 * \a creator - Creator of this Wavelet
		 *
		 * \a title - Title of the Wavelet
		 *	
		 * \a isRoot - True if this is the root Wavelet; if this value
		 * is set and the parent WaveModel does not have a root Wavelet yet,
		 * this Wavelet is set as the Wave's root Wavelet
		 *
		 * \a created - Date of creation
		 *
		 * \a lastModified - Date of last modification
		 *
		 * \a version - Version of the Wavelet
		 */
		public function Wavelet(
			wave:WaveModel,
			id:String,
			creator:Participant,
			title:String,
			isRoot:Boolean,
			created:Date,
			lastModified:Date,
			version:int,
			target:IEventDispatcher = null
		)
		{
			super(target);
			this.wave = wave;
			this.id = id;
			this.creator = creator;
			this._title = title;
			this.root = isRoot;
			this.created = created;
			this._lastModified = lastModified;
			this.version = version;
			this.rootBlip = null;
			this._status = "clean";
			this.participants = new Dictionary();
			this.blips = new ArrayCollection();
			if (isRoot) {
				if (wave.rootWavelet == null)
					wave.rootWavelet = this;
				else
					this.root = false;
			}
		}
		
		public function set title(title:String):void
		{
			if (this._title == title)
				return;
			this._title = title;
			this.fireTitleChanged(title);
		}
		
		public function get title():String
		{
			return this._title;
		}
		
		/**
		 * Add a participant to this Wavelet.
		 *
		 * Note: Fires participantsChanged()
		 */
		public function addParticipant(participant:Participant):void
		{
			
			{
				this.participants[participant.id] = participant;
				this.fireParticipantsChanged();
			}
		}
		
		/**
		 * Removes a participant from this Wavelet.
		 *
		 * Note: Fires participantsChanged()
		 */
		public function removeParticipant(participantId:String):void
		{
			if (this.participants[participantId] != null) {
				delete participants[participantId];
				this.fireParticipantsChanged();
			}
		}
		
		/**
		 * Returns the Participant object with the given id, if the participant
		 * resides on this Wavelet. Returns null otherwise.
		 */
		public function participant(id:String):Participant
		{
			return this.participants[id];
		}
		
		/**
		 * @property Wavelet::participantCount
		 * \brief the number of Participants on this Wavelet
		 */
		public function participantCount():int
		{
			var i:int = 0;
			for each (var p:Participant in participants)
			i++;
			return i;
		}
		
		/**
		 * Returns a list of all participants on this Wavelet.
		 */
		public function allParticipants():ArrayCollection
		{
			var participantList:ArrayCollection = new ArrayCollection();
			for each (var p:Participant in this.participants)
			participantList.addItem(p);
			return participantList;
		}
		
		/**
		 * Returns a list of all IDs of the participants on this Wavelet.
		 */
		public function allParticipantIDs():ArrayCollection
		{
			var participantIdList:ArrayCollection = new ArrayCollection();
			for (var pid:String in this.participants)
				participantIdList.addItem(pid);
			return participantIdList;
		}
		
		/**
		 * @property Wavelet::allParticipantsForGadget
		 * \brief a ready-to-use map of all participants on the Wavelet in Gadget API format.
		 */
		public function allParticipantsForGadget():Object
		{
			var ret:Object;
			for (var id:String in this.participants)
				ret[id] = this.participants[id].toGadgetFormat();
			return ret;
		}
		
		/**
		 * Convenience function for inserting a new Blip at the end.
		 *
		 * For parameters see the \link Blip::Blip Blip constructor\endlink.
		 *
		 * Note: Fires blipInserted()
		 */
		public function appendBlip(
			id:String,
			content:String,
			elements:ArrayCollection,
			creator:Participant,
			contributors:Dictionary,
			isRoot:Boolean,
			lastModified:Date,
			version:int = 0,
			submitted:Boolean = false
		):Blip
			{
				return this.insertBlip(this.blips.length, id, content, elements, creator, contributors, isRoot, lastModified, version, submitted);
			}
			
			/**
			 * Insert a new Blip at the specified index.
			 *
			 * For parameters see the \link Blip::Blip Blip constructor\endlink.
			 *
			 * Note: Fires blipInserted()
			 */
			public function insertBlip(
				index:int,
				id:String,
				content:String,
				elements:ArrayCollection,
				creator:Participant,
				contributors:Dictionary,
				isRoot:Boolean,
				lastModified:Date,
				version:int,
				submitted:Boolean
			):Blip
			{
				var blip:Blip = new Blip(this, id, content, elements, null, creator, contributors, isRoot, lastModified, version, submitted);
				this.blips.addItemAt(blip, index);
				this.fireBlipInserted(index, blip.id);
				return blip;
			}
			
			/**
			 * Delete a Blip by its id.
			 *
			 * Note: Fires blipDeleted()
			 */
			public function deleteBlip(id:String):void
			{
				for (var i:int = 0; i < this.blips.length; i++) {
					var blip:Blip = this.blips.getItemAt(i) as Blip;
					if (blip.id == id) {
						this.blips.removeItemAt(i);
						this.fireBlipDeleted(id);
						break;
					}
				}
			}
			
			/**
			 * Returns the Blip object at the given \a index.
			 */
			public function blipByIndex(index:int):Blip
		{
			if (index < 0 || index >= this.blips.length)
				return null;
			return this.blips.getItemAt(index) as Blip;
		}
		
		/**
		 * Returns the Blip object with the given \a id, if the Blip resides on this
		 * Wavelet. Returns null otherwise.
		 */
		public function blipById(id:String):Blip
		{
			for each (var blip:Blip in this.blips) {
				if (blip.id == id)
					return blip;
			}
			return null;
		}
		
//		/**
//		 * Returns a list of all Blips on this Wavelet, starting with the root Blip.
//		 */
//		QList<Blip*> Wavelet::allBlips() const
//		{
//			const P_D(Wavelet);
//			return d->m_blips;
//		}
		
		/**
		 * Returns a list of all IDs of the Blips on this Wavelet, starting with
		 * the root Blip.
		 */
		public function allBlipIDs():ArrayCollection
		{
			var ids:ArrayCollection = new ArrayCollection();
			for each (var blip:Blip in this.blips)
				ids.addItem(blip.id);
			return ids;
		}
		
		/**
		 * \internal
		 * Sets the root Blip of this Wavelet
		 */
		private function setRootBlip(blip:Blip):void
		{
			this.rootBlip = blip;
		}
		
		/**
		 * @property Wavelet::status
		 * \brief the status of this Wavelet
		 *
		 * Can be "clean", "dirty" and "invalid".
		 */
		public function get status():String
		{
			return this._status;
		}
		
		public function set status(status:String):void
			{
				if (this._status != status) {
					this._status = status;
					this.fireStatusChange(status);
				}
			}
			
		/**
		 * @property Wavelet::lastModified
		 * \brief the date/time of the last modification of this Wavelet
		 */
		public function get lastModified():Date
		{
			return this._lastModified;
		}
		public function set lastModified(value:Date):void
			{
				if (this._lastModified != value) {
					this._lastModified = value;
					this.fireLastModifiedChanged(value);
				}
			}
			
			/**
			 * Calculate and compare checksums of all Blips to the given map.
			 *
			 *Fires statusChange() if the status changes.
			 */
			public function checkSync(blipsums:Dictionary):void
			{
				var valid:Boolean = true;
				
				for (var blipId:String in blipsums) {
					var blip:Blip = this.blipById(blipId);
					if (blip != null && !blip.checkSync(blipsums[blipId] as String))
						valid = false;
				}
				
				if (valid)
					this.status = 'clean';
				else
					this.status = 'invalid';
			}
			
			/**
			 * Apply operations on the wavelet.
			*/
			public function applyOperations(
				operations:ArrayCollection,
				timestamp:Date,
				contributorId:String
			):void
			{
				var pp:IParticipantProvider = this.wave.pp;
				var contributor:Participant = pp.participant(contributorId);
				
				for (var i:int; i < operations.length; i++) {
					var op:Operation = operations.getItemAt(i) as Operation;
					var property:Object;
					if (op.blipId != '') {
						var blip:Blip = this.blipById(op.blipId);
						if (!blip)
							continue;
						switch(op.type) {
							case Operation.DOCUMENT_NOOP:
								break;
							case Operation.DOCUMENT_DELETE:
								blip.deleteText(op.index, op.property as int, contributor);
								break;
							case Operation.DOCUMENT_INSERT:
								blip.insertText(op.index, op.property as String, contributor);
								break;
							case Operation.DOCUMENT_ELEMENT_DELETE:
								blip.deleteElement(op.index, contributor);
								break;
							case Operation.DOCUMENT_ELEMENT_INSERT:
								property = op.property;
								blip.insertElement(op.index, property["type"], property["properties"], contributor);
								break;
							case Operation.DOCUMENT_ELEMENT_DELTA:
								blip.applyElementDelta(op.index, op.property, contributor);
								break;
							case Operation.DOCUMENT_ELEMENT_SETPREF:
								property = op.property();
								blip.setElementUserpref(op.index, property["key"], property["value"], contributor);
								break;
							case Operation.BLIP_DELETE:
								this.deleteBlip(op.blipId);
								continue;
							default:
								break;
						}
						blip.lastModified = timestamp;
					}
					else {
						switch(op.type) {
							case Operation.WAVELET_ADD_PARTICIPANT:
								this.addParticipant(pp.participant(op.property as String));
								break;
							case Operation.WAVELET_REMOVE_PARTICIPANT:
								this.removeParticipant(op.property as String);
								break;
							case Operation.WAVELET_APPEND_BLIP:
								this.appendBlip(op.property["blipId"], '', new ArrayCollection(), contributor, new Dictionary(), false, timestamp, 0, false);
								default:
								break;
						}
					}
				}
				
				this._lastModified = timestamp;
			}
			
			/**
			 * Updates the ID of operations on temporary Blips.
			 */
			public function updateBlipId(tempId:String, blipId:String):void
			{
				var blip:Blip = this.blipById(tempId);
				if (blip != null)
					blip.id = blipId;
			}
			
			/**
			 * Load the Blips from a snapshot. Removes previously existing Blips first.
			 */
			public function loadBlipsFromSnapshot(blips:Object, rootBlipId:String):void
			{
				 var pp:IParticipantProvider = this.wave.pp;
				
				// Remove existing
				while (this.blips.length > 0)
				{
					var oldBlip:Blip =  this.blips.getItemAt(this.blips.length - 1) as Blip;
					this.deleteBlip(oldBlip.id);
				}
				
				// TODO Ordering
//				QMap<quint64, QByteArray> created;
//				foreach (QString s_blip_id, blips.keys()) {
//					QByteArray blip_id = s_blip_id.toAscii();
//					created.insert(blips[blip_id].toMap()["creationTime"].toULongLong(), blip_id);
//				}
				
				var sortedBlips:ArrayCollection = new ArrayCollection();
				
				for each (var tmpBlip:Object in blips) {
					sortedBlips.addItem(tmpBlip);	
				}
				var sort:Sort = new Sort();
				sort.fields = [new SortField('creationTime')];
				sortedBlips.sort = sort;
				sortedBlips.refresh();
				
				// Note: QMap is always sorted by key
				for each (var blip:Object in sortedBlips) {
					var contributors:Dictionary = new Dictionary();
					for each (var v_cid:String in blip["contributors"])
						contributors[v_cid] = pp.participant(v_cid);
					
					var blip_elements:ArrayCollection = new ArrayCollection();
					for each (var melement:Object in blip["elements"]) {
						var properties:Object = melement["properties"];
						if (melement["type"] == Element.GADGET)
							blip_elements.addItem(new GadgetElement(
								null,
								melement["id"],
								melement["index"],
								properties
							));
						else
							blip_elements.addItem(new Element(
								null,
								melement["id"],
								melement["index"],
								melement["type"],
								properties
							));
					}
					
					this.appendBlip(
						blip.blipId,
						blip["content"],
						blip_elements,
						pp.participant(blip["creator"]),
						contributors,
						blip.blipId == rootBlipId,
						new Date(blip["lastModifiedTime"]),
						blip["version"],
						blip["submitted"]
					);
				}
			}
		
		
		private function fireParticipantsChanged():void
		{
			var data:Object = new Object();
			this.dispatchEvent(new PygowaveEvent('participantsChanged', data));
		}
		
		private function fireTitleChanged(title:String):void
		{
			var data:Object = new Object();
			data.title = title;
			this.dispatchEvent(new PygowaveEvent('titleChanged', data));
		}
		
		private function fireBlipInserted(index:int, id:String):void
		{
			var data:Object = new Object();
			data.index = index;
			data.id = id;
			this.dispatchEvent(new PygowaveEvent('blipInserted', data));
		}
		
		private function fireBlipDeleted(id:String):void
		{
			var data:Object = new Object();
			data.id = id;
			this.dispatchEvent(new PygowaveEvent('blipDeleted', data));
		}
		
		private function fireStatusChange(status:String):void
		{
			var data:Object = new Object();
			data.status = status;
			this.dispatchEvent(new PygowaveEvent('statusChange', data));
		}
		
		private function fireLastModifiedChanged(value:Date):void
		{
			var data:Object = new Object();
			data.value = data;
			this.dispatchEvent(new PygowaveEvent('lastModifiedChanged', data));
		}
	}
}