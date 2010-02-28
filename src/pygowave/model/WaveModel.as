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
package pygowave.model
{
	import pygowave.event.PygowaveEvent;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;

	public class WaveModel extends EventDispatcher
	{
		public var rootWavelet:Wavelet;
		public var waveId:String;
		public var viewerId:String;
		public var pp:IParticipantProvider;
		public var wavelets:Dictionary;
		
		/**
		 * Constructs a new WaveModel object.
		 *
		 * viewerId is the Participant ID of the wave viewer.
		 */
		public function WaveModel(waveId:String, viewerId:String, pp:IParticipantProvider, target:IEventDispatcher=null)
		{
			super(target);
			this.rootWavelet = null;
			this.waveId = waveId;
			this.viewerId = viewerId;
			this.pp = pp;
			this.wavelets = new Dictionary();
		}
		
//		/**
//		 * Destroys the WaveModel and its child Wavelets. Emits
//		 * waveletAboutToBeRemoved() once per Wavelet.
//		 */
//		WaveModel::~WaveModel()
//		{
//			P_D(WaveModel);
//			foreach (QByteArray id, d->m_wavelets.keys())
//			this->removeWavelet(id);
//			delete this->pd_ptr;
//		}
		
		
		/**
		 * Load the wave's contents from a JSON-serialized snapshot and a map of
		 * participant objects.
		 */
		public function loadFromSnapshot(obj:Object):void
		{
			var rootWavelet:Object = obj.wavelet;
			var waveletId:String = rootWavelet.waveletId;
			var rootWaveletObj:Wavelet = this.createWavelet(
				waveletId,
				this.pp.participant(rootWavelet.creator),
				rootWavelet.title,
				true,
				rootWavelet.creationTime,
				rootWavelet.lastModifiedTime,
				rootWavelet.version
			);
			
			for each (var part_id:String in rootWavelet.participants as ArrayCollection) {
				rootWaveletObj.addParticipant(this.pp.participant(part_id));
			}
			
			var blips:Object = obj.blips;
			rootWaveletObj.loadBlipsFromSnapshot(blips, rootWavelet.rootBlipId);
		}
			
		/**
		 * Create a Wavelet and add it to this Wave. For parameters see the
		 * \link Wavelet::Wavelet Wavelet constructor\endlink.
		 *
		 * Note: Fires waveletAdded()
		 */
		public function createWavelet(id:String, creator:Participant, title:String, isRoot:Boolean, created:Date, lastModified:Date, version:int):Wavelet
		{
			var w:Wavelet = new Wavelet(this, id, creator, title, isRoot, created, lastModified, version);
			this.wavelets[id] = w;
			this.fireWaveletAdded(id, isRoot);
			return w;
		}
			
//		/**
//		 * Return a Wavelet of this Wave by its \a id.
//		 */
//		public function wavelet(id:String):Wavelet
//		{
//			if (!this.wavelets.)
//				return null;
//			return this.wavelets.id];
//		}
		
//		/*!
//		Return a list of all Wavelets on this Wave.
//		*/
//		QList<Wavelet*> WaveModel::allWavelets() const
//		{
//			const P_D(WaveModel);
//			return d->m_wavelets.values();
//		}
		
		/**
		 * Removes and deletes a wavelet by its id. Emits waveletAboutToBeRemoved() beforehand.
		 */
		public function removeWavelet(waveletId:String):void
		{
			var wavelet:Wavelet = this.wavelets[waveletId];
			if (wavelet == null)
				return;
			
			this.fireWaveletAboutToBeRemoved(waveletId);
			delete this.wavelets[waveletId];
			if (wavelet == this.rootWavelet)
				this.rootWavelet = null;
		}	
		
		private function fireWaveletAdded(id:String, isRoot:Boolean):void
		{
			var data:Object = new Object();
			data.id = id;
			data.isRoot = isRoot;
			this.dispatchEvent(new PygowaveEvent('waveletAdded', data));
		}
		
		private function fireWaveletAboutToBeRemoved(id:String):void
		{
			var data:Object = new Object();
			data.id = id;
			this.dispatchEvent(new PygowaveEvent('waveletAboutToBeRemoved', data));
		}
	}
}