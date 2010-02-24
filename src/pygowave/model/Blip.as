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
	import pygowave.event.PygowaveEvent;

	import com.adobe.crypto.SHA1;
	import com.adobe.utils.DictionaryUtil;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;

	/**
	 * \class PyGoWave::Blip
	 * \brief Models a Blip in a Wavelet.
	 *
	 * This class should not be instanitated directly. Please
	 * use \link Wavelet::appendBlip() \endlink.
	 */
	public class Blip extends EventDispatcher
	{
		public var wavelet:Wavelet;
		private var _id:String;
		[Bindable]
		public var content:String;
		public var elements:ArrayCollection;
		public var annotations:ArrayCollection;
		public var parent:Blip;
		public var creator:Participant;
		public var contributors:Dictionary;
		public var root:Boolean;
		private var _lastModified:Date;
		public var version:int;
		public var submitted:Boolean;
		private var outofsync:Boolean;
		private static var g_lastTempId:int = 0;
				
		/**
		 * Creates a new Blip object.
		 *
		 * @param wavelet Parent Wavelet object
		 * @param id ID of the Blip, setting this to an empty string will
		 * assign a new temporary ID
		 * @param content Content of the Blip
		 * @param elements Element objects which initially
		 * reside in this Blip
		 * @param parent Parent Blip if this is a nested Blip
		 * @param creator Creator of this Blip
		 * @param isRoot True if this is the root Blip; if this value
		 * is set and the parent Wavelet does not have a root Blip yet,
		 * this Blip is set as the Wavelet's root Blip
		 * @param lastModified Date/Time of last modification
		 * @param version Version of the Blip
		 * @param submitted True if this Blip is submitted
		 */
		public function Blip(
			wavelet:Wavelet,
			id:String,
			content:String,
			elements:ArrayCollection,
			parent:Blip,
			creator:Participant,
			contributors:Dictionary,
			isRoot:Boolean,
			lastModified:Date,
			version:int,
			submitted:Boolean,
			target:IEventDispatcher=null
		)
		{
			super(target);
			this.wavelet = wavelet;
			if (id == null || id == '')
				this._id = this.newTempId();
			else
				this._id = id;
			this.parent = parent;
			this.content = content;
			this.elements = elements;
			for each (var element:Element in elements)
				element.blip = this;
			this.creator = creator;
			this.contributors = new Dictionary();
			for each (var c:Participant in contributors)
				this.contributors[c.id] = c;
			if (DictionaryUtil.getKeys(this.contributors).length == 0 && creator != null)
				this.contributors[creator.id] = creator;
			this.root = isRoot;
			this._lastModified = lastModified;
			this.version = version;
			this.submitted = submitted;
			this.outofsync = false;
		}
		
		/**
		 * @property Blip::id
		 * \brief the ID of this Blip.
		 */
		[Bindable]
		public function get id():String
		{
			return this._id;
		}
		
		/**
		 * Sets the ID of this Blip. Mainly used for temporary Blips.
		 */
		public function set id(id:String):void
			{
				if (this._id != id) {
					var oldId:String = this._id;
					this._id = id;
					this.fireIdChanged(oldId, id);
				}
			}
			
		/**
		 * Returns an Element by its \a id.
		 */
		public function elementById(id:String):Element
		{
			for each (var element:Element in this.elements) {
				if (element.id == id)
					return element;
			}
			return null;
		}
		
		/**
		 *Returns the Element object at the given \a index or null.
		 */
		public function elementAt(index:int):Element
		{
			for each (var element:Element in this.elements) {
				if (element.position == index)
					return element;
			}
			return null;
		}
		
		/**
		 * Returns the Elements between the \a start and \a end index.
		 */
		public function elementsWithin(start:int, end:int):ArrayCollection
		{
			var lst:ArrayCollection = new ArrayCollection();
			
			for each (var element:Element in this.elements) {
				if (element.position >= start && element.position < end)
					lst.addItem(element);
			}
			return lst;
		}
		
		/**
		 * Returns all Elements of this Blip.
		 */
		public function allElements():ArrayCollection
		{
			return this.elements;
		}
		
		/**
		 * Returns all contributors to this Blip.
		 */
		public function allContributors():Dictionary
		{
			return this.contributors;
		}
		
		/**
		 * Add a contributor to this Blip if he is not already contributing.
		 */
		public function addContributor(contributor:Participant):void
		{
			if (!DictionaryUtil.getKeys(this.contributors).indexOf(contributor.id)) {
				this.contributors[contributor.id] = contributor;
				this.fireContributorAdded(contributor.id);
			}
		}
		
		/**
		 * Insert a \a text at the specified \a index. This moves annotations and
		 * elements as appropriate.
		 *
		 * Note: This sets the wavelet status to 'dirty'.
		 * Set \a noevent to true, to prevent the emission of a insertedText() signal.
		 */
		public function insertText(index:int, text:String, contributor:Participant, noevent:Boolean = false):void
		{			
			this.addContributor(contributor);
			
			this.content= this.content.slice(0, index) + text + this.content.slice(index, this.content.length);
			
			var length:int = text.length;
			
			for each (var element:Element in this.elements) {
				if (element.position >= index)
					element.position = element.position + length;
			}
			
			for each (var anno:Annotation in this.annotations) {
				if (anno.start >= index) {
					anno.start = anno.start + length;
					anno.end = anno.end + length;
				}
			}
			
			this.wavelet.status = "dirty";
			if (!noevent)
				this.fireInsertedText(index, text);
		}
		
		/**
		 * Delete text at the specified \a index with the given \a length.
		 * This moves annotations and elements as appropriate.
		 *
		 * Note: This sets the wavelet status to 'dirty'.
		 * Set \a noevent to true, to prevent the emission of a deletedText() signal.
		 */
		public function deleteText(index:int, length:int, contributor:Participant, noevent:Boolean=false):void
		{			
			this.addContributor(contributor);
			
			this.content = this.content.substr(0, index) + this.content.substr(index + length, this.content.length);
			
			for each (var element:Element in this.elements) { 
				if (element.position >= index)
					element.position = element.position - length;
			}
			
			for each (var anno:Annotation in this.annotations) {
				if (anno.start >= index) {
					anno.start = anno.start - length;
					anno.end = anno.end - length;
				}
			}
			
			this.wavelet.status = "dirty";
			if (!noevent)
				this.fireDeletedText(index, length);
		}
		
		/**
		 * Insert an element at the specified \a index. This implicitly adds a
		 * protected newline character at the index.
		 *
		 * Note: This sets the wavelet status to 'dirty'.
		 * Set \a noevent to true, to prevent the emission of a insertedElement() signal.
		 */
		public function insertElement(index:int, type:String, properties:Object, contributor:Participant, noevent:Boolean=false):void
		{
			
			this.addContributor(contributor);
			
			this.insertText(index, '\n', contributor, true);
			
			var elt:Element;
			if (type == Element.GADGET)
				elt = new GadgetElement(this, -1, index, properties);
			else
				elt = new Element(this, -1, index, type, properties);
			this.elements.addItem(elt);
			
			this.wavelet.status = "dirty";
			if (!noevent)
				this.fireInsertedElement(index);
		}
		
		/**
		 * Delete an element at the specified \a index. This implicitly deletes the
		 * protected newline character at the index.
		 *
		 * Note: This sets the wavelet status to 'dirty'.
		 * Set \a noevent to true, to prevent the emission of a deletedElement() signal.
		 */
		public function deleteElement(index:int, contributor:Participant, noevent:Boolean = false):void
		{
			
			this.addContributor(contributor);
			
			for (var i:int = 0; i < this.elements.length; i++) {
				var elt:Element = this.elements.getItemAt(i) as Element;
				if (elt.position == index) {
					this.elements.removeItemAt(i);
					this.deleteText(index, 1, contributor, true);
					if (!noevent)
						this.fireDeletedElement(index);
					break;
				}
			}
		}
		
		/**
		 * Apply an element delta on the element at the specified \a index.
		 * Currently only for gadget elements.
		 *
		 * Note: This action always emits \link GadgetElement::stateChange \endlink.
		 */
		public function applyElementDelta(index:int, delta:Object, contributor:Participant):void
		{
			this.addContributor(contributor);
			
			var elt:GadgetElement = this.elementAt(index) as GadgetElement;
			if (elt != null)
				elt.applyDelta(delta);
		}
		
		/**
		 * Set an UserPref of an element at the specified \a index.
		 * Currently only for gadget elements.
		 *
		 * Set \a noevent to true, to prevent the emission of a \link GadgetElement::userPrefSet \endlink signal.
		 */
		public function setElementUserpref(index:int, key:String, value:String, contributor:Participant, noevent:Boolean = false):void
		{
			this.addContributor(contributor);
			
			var elt:GadgetElement = this.elementAt(index) as GadgetElement;
			if (elt != null)
				elt.setUserPref(key, value, noevent);
		}
		
		/**
		 * Calculate a checksum of this Blip and compare it against the given
		 * checksum. Fires outOfSync() if the checksum is wrong. Returns true if the checksum is ok.
		 *
		 * Note: Currently this only calculates the SHA-1 of the Blip's text. This
		 * is tentative and subject to change.
		 */
		public function checkSync(sum:String):Boolean {
			// TODO check
			var mysum:String = SHA1.hash(this.content);//.toHex();
			if (sum != mysum) {
				this.fireOutOfSync();
				this.outofsync = true;
				return false;
			}
			return true;
		}
			
		/**
		 * @property Blip::lastModified
		 * \brief the date/time of the last modification of this Blip
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
		 * \internal
		 * Creates a new temporary ID.
		 */
		private function newTempId():String
		{
			Blip.g_lastTempId++;
			var newId:String = "TBD_";
			if (Blip.g_lastTempId < 10)
				newId += '0';
			newId += Blip.g_lastTempId;
			return newId;
		}
		
		private function fireLastModifiedChanged(value:Date):void
		{
			var data:Object = new Object();
			data.value = value;
			this.dispatchEvent(new PygowaveEvent('lastModifiedChanged', data));
		}
		
		private function fireIdChanged(oldId:String, id:String):void
		{
			var data:Object = new Object();
			data.oldId = oldId;
			data.id = id;
			this.dispatchEvent(new PygowaveEvent('idChanged', data));
		}
		
		private function fireContributorAdded(id:String):void
		{
			var data:Object = new Object();
			data.id = id;
			this.dispatchEvent(new PygowaveEvent('contributorAdded', data));
		}
		
		private function fireInsertedText(index:int, text:String):void
		{
			var data:Object = new Object();
			data.index = index;
			data.text = text;
			this.dispatchEvent(new PygowaveEvent('insertedText', data));
		}
		
		private function fireDeletedText(index:int, length:int):void
		{
			var data:Object = new Object();
			data.index = index;
			data.length = length;
			this.dispatchEvent(new PygowaveEvent('deletedText', data));
		}
		
		private function fireInsertedElement(index:int):void
		{
			var data:Object = new Object();
			data.index = index;
			this.dispatchEvent(new PygowaveEvent('insertedElement', data));
		}
		
		private function fireDeletedElement(index:int):void
		{
			var data:Object = new Object();
			data.index = index;
			this.dispatchEvent(new PygowaveEvent('deletedElement', data));
		}
		
		private function fireOutOfSync():void
		{
			var data:Object = new Object();
			this.dispatchEvent(new PygowaveEvent('outOfSync', data));
		}
	}
}