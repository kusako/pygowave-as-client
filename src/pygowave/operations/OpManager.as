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
package pygowave.operations
{
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import mx.collections.ArrayCollection;
	import pygowave.event.OperationChangedEvent;
	import pygowave.event.OperationsEvent;
	
	/**
	 *  Manages operations: Creating, merging, transforming, serializing.
	 * The operation manager wraps single operations as functions and generates
	 * operations in-order. It keeps a list of operations and allows
	 * transformation, merging and serializing.
	 * An OpManager is always associated with exactly one wave/wavelet.
	 * --- Event documentation ---
	 * Fired if an operation in this manager has been changed.
	 * @event onOperationChanged
	 * @param {int} index Index of the changed operation
	 
	 * Fired if one or more operations are about to be removed.
	 * @event onBeforeOperationsRemoved
	 * @param {int} start Start index of the removal.
	 * @param {int} end End index of the removal.
	 *
	 * Fired if one or more operations have been removed.
	 * @event onAfterOperationsRemoved
	 * @param {int} start Start index of the removal.
	 
	 * @param {int} end End index of the removal.
	 
	 * Fired if one or more operations are about to be inserted.
	 * @event onBeforeOperationsInserted
	 * @param {int} start Start index of the insertion.
	 * @param {int} end End index of the insertion.
	 *
	 * *Fired if one or more operations have been inserted.
	 * @event onAfterOperationsInserted
	 * @param {int} start Start index of the insertion.
	 * @param {int} end End index of the insertion.
	 */
	public class OpManager extends EventDispatcher
	{
		public var waveId:String;
		public var waveletId:String;
		public var contributorId:String;
		public var operations:ArrayCollection;
		public var lockedBlips:ArrayCollection;
		
		/**
		 * Constructs the op manager with a \a waveId and \a waveletId.
		 */
		public function OpManager(waveId:String, waveletId:String, contributorId:String, target:IEventDispatcher=null)
		{
			super(target);
			this.waveId = waveId;
			this.waveletId = waveletId;
			this.contributorId = contributorId;
			this.operations = new ArrayCollection();
			this.lockedBlips = new ArrayCollection();
		}
		
		/**
		 * Return true if this manager is not holding operations.
		 */
		public function isEmpty():Boolean
		{
			return (this.operations.length <= 0);
		}
		
		/**
		 * Returns if the manager holds fetchable operations i.e. that are not
		 * locked.
		 */
		public function canFetch():Boolean
		{
			for each (var op:Operation in this.operations)
			{
				if (!this.lockedBlips.contains(op.blipId))
				{
						return true;
				}
			}
			return false;
		}
		
		/**
		* Transform the input operation on behalf of the manager's operations
		* list. This will simultaneously transform the operations list on behalf
		* of the input operation.
		* 
		* This method returns a list of applicable operations. This list may be
		* empty or it may contain any number of new operations (according to
		* results of deletion, modification and splitting; i.e. the input
		* operation is not modified by itself).
		*/
		public function transform(input_op:Operation):ArrayCollection
		{
			var new_op:Operation = null;
			var op_lst:ArrayCollection = new ArrayCollection();
			op_lst.addItem(input_op.clone());
			var i:int = 0;
			
			while (i < this.operations.length) {
				var myop:Operation = this.operations[i];
				var j:int = 0;
				while (j < op_lst.length) {
					var op:Operation = op_lst[j];
					if (!op.isCompatibleTo(myop))
						continue;
					var end:int = 0;
					if (op.isDelete() && myop.isDelete()) {
						if (op.index < myop.index) {
							end = op.index + op.length;
							if (end <= myop.index) {
								myop.index = myop.index - op.length;
								this.fireOperationChanged(i);
							}
							else if (end < (myop.index + myop.length)) 
							{
								op.resize(myop.index - op.index);
								myop.resize(myop.length - (end - myop.index));
								myop.index = op.index;
								this.fireOperationChanged(i);
							}
							else 
							{
								op.resize(op.length - myop.length);
								myop = null;
								this.removeOperation(i);
								i--;
								break;
							}
						}
						else 
						{
							end = myop.index + myop.length;
							if (op.index >= end)
								op.index = op.index - myop.length;
							else if (op.index + op.length <= end) 
							{
								myop.resize(myop.length - op.length);
								op_lst.removeItemAt(j);
								op = null;
								j--;
								if (myop.isNull()) 
								{
									myop = null;
									this.removeOperation(i);
									i--;
									break;
								}
								else
									this.fireOperationChanged(i);
							}
							else 
							{
								myop.resize(myop.length - (end - op.index));
								this.fireOperationChanged(i);
								op.resize(op.length - (end - op.index));
								op.index = myop.index;
							}
						}
					}
					else if (op.isDelete() && myop.isInsert()) 
					{
						if (op.index < myop.index) 
						{
							if (op.index + op.length <= myop.index) 
							{
								myop.index = myop.index - op.length;
								this.fireOperationChanged(i);
							}
							else 
							{
								new_op = op.clone();
								op.resize(myop.index - op.index);
								new_op.resize(new_op.length - op.length);
								op_lst.addItemAt(new_op, j + 1);
								myop.index = myop.index - op.length;
								this.fireOperationChanged(i);
							}
						}
						else
							op.index = op.index + myop.length;
					}
					else if (op.isInsert() && myop.isDelete()) 
					{
						if (op.index <= myop.index) 
						{
							myop.index = myop.index + op.length;
							this.fireOperationChanged(i);
						}
						else if (op.index >= (myop.index + myop.length))
							op.index = op.index - myop.length;
						else 
						{
							new_op = myop.clone();
							myop.resize(op.index - myop.index);
							this.fireOperationChanged(i);
							new_op.resize(new_op.length - myop.length);
							this.insertOperation(i + 1, new_op);
							op.index = myop.index;
						}
					}
					else if (op.isInsert() && myop.isInsert()) 
					{
						if (op.index <= myop.index) 
						{
							myop.index = myop.index + op.length;
							this.fireOperationChanged(i);
						}
						else
							op.index = op.index + myop.length;
					}
					else if (op.isChange() && myop.isDelete()) 
					{
						if (op.index > myop.index) 
						{
							if (op.index <= (myop.index + myop.length))
								op.index = myop.index;
							else
								op.index = op.index - myop.length;
						}
					}
					else if (op.isChange() && myop.isInsert()) 
					{
						if (op.index >= myop.index)
							op.index = op.index + myop.length;
					}
					else if (op.isDelete() && myop.isChange()) 
					{
						if (op.index < myop.index) {
							if (myop.index <= (op.index + op.length)) 
							{
								myop.index = op.index;
								this.fireOperationChanged(i);
							}
							else 
							{
								myop.index = myop.index - op.length;
								this.fireOperationChanged(i);
							}
						}
					}
					else if (op.isInsert() && myop.isChange()) 
					{
						if (op.index <= myop.index) 
						{
							myop.index = myop.index + op.length;
							this.fireOperationChanged(i);
						}
					}
					else if ((op.type == Operation.WAVELET_ADD_PARTICIPANT && myop.type == Operation.WAVELET_ADD_PARTICIPANT)
						|| (op.type == Operation.WAVELET_REMOVE_PARTICIPANT && myop.type == Operation.WAVELET_REMOVE_PARTICIPANT)) 
					{
						if (op.property == myop.property) 
						{
							myop = null;
							this.removeOperation(i);
							i--;
							break;
						}
					}
					else if (op.type == Operation.BLIP_DELETE && !((op.blipId == null) || (op.blipId.length <= 0)) && !((myop.blipId == null) || (myop.blipId.length <= 0))) 
					{
						myop = null;
						this.removeOperation(i);
						i--;
						break;
					}
					j++;
				}
				i++;
			}

			return op_lst;			
		}
		
        /**
         * Returns the pending operations and removes them from this manager.
         */
		public function fetch():ArrayCollection
        {
            var ops:ArrayCollection = new ArrayCollection();
            var i:int = 0;
            var s:int = 0;
            while (i < this.operations.length) {
                var op:Operation  = operations.getItemAt(i) as Operation;
                if (this.lockedBlips.contains(op.blipId)) 
                {
                    if (i - s > 0) 
                    {
                        this.removeOperations(s, i-1, false);
                        i -= s+1;
                    }
                    s = i+1;
                }
                else
                    ops.addItem(op);
                i++;
            }
            if (i - s > 0)
                this.removeOperations(s, i-1, false);
 
            return ops;               
		}
		
        /**
         * Opposite of fetch. Inserts all given operations into this manager.
         * @param put operations
         */
        public function put(ops:ArrayCollection):void
        {
			if (ops.length == 0)
    			return;
			var start:int = this.operations.length;
			var end:int = start + ops.length - 1;
			this.fireBeforeOperationsInserted(start, end);
			this.operations.addAll(ops);
			this.fireAfterOperationsInserted(start, end);
		}
        
        /**
         * Serialize this manager's operations into a list of dictionaries.
         * Set fetch to true to also clear this manager.
         */
        public function serialize(fetch:Boolean=false):Array
        {
			var ops:ArrayCollection;
			
			if (fetch)
		        ops = this.fetch();
			else
                ops = this.operations;
			 
			var out:ArrayCollection = new ArrayCollection();
            for each (var op:Operation in ops)
                out.addItem(op.serialize());
			 
			if (fetch) 
			{
				ops.removeAll();
			}
			return out.source;
		}
        
        /**
         * Unserialize a list of dictionaries to operations and add them to this
         * manager.
         */
        public function unserialize(serial_ops:ArrayCollection):void
        {
			var ops:ArrayCollection = new ArrayCollection();
			for each (var op:Object in serial_ops)
                ops.addItem(Operation.unserialize(op));
			this.put(ops);
		}
        
		/**
		 * Requests to insert content into a document at a specific location.
		 *
		 * @param blipId The Blip id that this operation is applied to
		 * @param index The position insert the content at in ths document
		 * @param content The content to insert
		 */
		public function documentInsert(blipId:String, index:int, content:String):void
		{
			var op:Operation = new Operation(
				Operation.DOCUMENT_INSERT,
				this.waveId,
				this.waveletId,
				blipId,
				index,
				content
			);
			this.mergeInsert(op);
				//delete op;
		}		
        
		/**
		 *Requests to delete content in a given range.
		 *
		 * @param blipId The Blip id that this operation is applied to
		 * @param start Start of the range
		 * @param end End of the range
		 */
		public function documentDelete(blipId:String, start:int, end:int):void
		{
			var op:Operation = new Operation(
				Operation.DOCUMENT_DELETE,
				this.waveId,
				this.waveletId,
				blipId,
				start,
				end-start
			);
			this.mergeInsert(op);
				// delete op;
		}
		
		/**
		 * Requests to insert an element at the given position.
		 *
		 * @param blipId The Blip id that this operation is applied to
		 * @param index Position of the new element
		 * @param type Element type
		 * @param properties Element properties
		 */
		public function documentElementInsert(blipId:String, index:int, type:int, properties:Object):void
		{
			var property:Object;
			property["type"] = type;
			property["properties"] = properties;
			var op:Operation = new Operation(
				Operation.DOCUMENT_ELEMENT_INSERT,
				this.waveId,
				this.waveletId,
				blipId,
				index,
				property
			);
			this.mergeInsert(op);
				// delete op;
		}

		/**
		 * Requests to delete an element from the given position.
		 *
		 * @param blipId The Blip id that this operation is applied to
		 * @param index Position of the element to delete
		 */
		public function documentElementDelete(blipId:String, index:int):void
		{
			var op:Operation = new Operation(
				Operation.DOCUMENT_ELEMENT_DELETE,
				this.waveId,
				this.waveletId,
				blipId,
				index,
				new Object()
			);
			this.mergeInsert(op);
				// delete op;
		}		

		/**
		 * Requests to apply a delta to the element at the given position.
		 *
		 * @param blipId The Blip id that this operation is applied to
		 * @param index Position of the element
		 * @param delta Delta to apply to the element
		 */
		public function documentElementDelta(blipId:String, index:int, delta:Object):void
		{
			var op:Operation = new Operation(
				Operation.DOCUMENT_ELEMENT_DELTA,
				this.waveId,
				this.waveletId,
				blipId,
				index,
				delta
			);
			this.mergeInsert(op);
				// delete op;
		}		

		/**
		 * Requests to set a UserPref of the element at the given position.
		 *
		 * @param blipId The Blip id that this operation is applied to
		 * @param index Position of the element
		 * @param key Name of the UserPref
		 * @param value Value of the UserPref
		 */
		public function documentElementSetpref(blipId:String, index:int, key:String, value:String):void
		{
			var property:Object;
			property["key"] = key;
			property["value"] = value;
			var op:Operation = new Operation(
				Operation.DOCUMENT_ELEMENT_SETPREF,
				this.waveId,
				this.waveletId,
				blipId,
				index,
				property
			);
			this.mergeInsert(op);
				// delete op;
		}

		/**
		 * Requests to add a Participant to the Wavelet.
		 *
		 * @param id ID of the Participant to add
		 */
		public function waveletAddParticipant(id:String):void
		{
			var op:Operation = new Operation(
				Operation.WAVELET_ADD_PARTICIPANT,
				this.waveId,
				this.waveletId,
				'',
				-1,
				id
			);
			this.mergeInsert(op);
				// delete op;
		}
		
		/**
		 * Requests to remove a Participant to the Wavelet.
		 *
		 * @param id ID of the Participant to remove
		 */
		public function waveletRemoveParticipant(id:String):void
		{
			var op:Operation = new Operation(
				Operation.WAVELET_REMOVE_PARTICIPANT,
				this.waveId,
				this.waveletId,
				'',
				-1,
				id
			);
			this.mergeInsert(op);
				// delete op;
		}		

		/**
		 * Requests to append a new Blip to the Wavelet.
		 *
		 * @param tempId Temporary Blip ID
		 */
		public function waveletAppendBlip(tempId:String):void
		{
			var property:Object = new Object();
			property["waveId"] = this.waveId;
			property["waveletId"] = this.waveletId;
			property["blipId"] = tempId;
			var op:Operation = new Operation(
				Operation.WAVELET_APPEND_BLIP,
				this.waveId,
				this.waveletId,
				'',
				-1,
				property
			);
			this.mergeInsert(op);
				// delete op;
		}		
	
		/**
		 * Requests to delete a Blip.
		 *
		 * @param blipId The Blip id that this operation is applied to
		 */
		public function blipDelete(blipId:String):void
		{
			var op:Operation = new Operation(
				Operation.BLIP_DELETE,
				this.waveId,
				this.waveletId,
				blipId
			);
			this.mergeInsert(op);
				// delete op;
		}		

		/**
		 * Requests to create a clild Blip.
		 *
		 * @param blipId The parent Blip
		 * @param tempId Temporary Blip ID
		 */
		public function blipCreateChild(blipId:String, tempId:String):void
		{
			var property:Object;
			property["waveId"] = this.waveId;
			property["waveletId"] = this.waveletId;
			property["blipId"] = tempId;
			var op:Operation = new Operation(
				Operation.BLIP_CREATE_CHILD,
				this.waveId,
				this.waveletId,
				blipId,
				-1,
				property
			);
			this.mergeInsert(op);
				// delete op;
		}

		
		/**
		 * internal
		 * Inserts and probably merges an operation into the manager's
		 * operation list.
		 */
		private function mergeInsert(newop:Operation):Boolean
		{
			var op:Operation = null;
			var i:int = 0;
			if (newop.type == Operation.DOCUMENT_ELEMENT_DELTA) {
				for (i = 0; i < this.operations.length; i++) {
					op = this.operations.getItemAt(i) as Operation;
					var dmap:Object = op.property;
					if (op.type == Operation.DOCUMENT_ELEMENT_DELTA && newop.property["id"] == dmap["id"]) {
						var delta:Object = dmap["delta"];
						var newdelta:Object = newop.property["delta"];

						for each (var key:Object in newdelta)
							delta[key] = newdelta[key];
						dmap["delta"] = delta;
						op.property = dmap;
						this.fireOperationChanged(i);
						return false;
					}
				}
			}
			i = this.operations.length - 1;
			if (i >= 0) {
				op = this.operations.getItemAt(i) as Operation;
				if (newop.type == Operation.DOCUMENT_INSERT && op.type == Operation.DOCUMENT_INSERT) {
					if (newop.index >= op.index && newop.index <= op.index+op.length) {
						op.insertString(newop.index - op.index, newop.property.toString());
						this.fireOperationChanged(i);
						return false;
					}
				}
				else if (newop.type == Operation.DOCUMENT_DELETE && op.type == Operation.DOCUMENT_INSERT) {
					if (newop.index >= op.index && newop.index < op.index+op.length) {
						var remain:int = op.length - (newop.index - op.index);
						if (remain > newop.length) {
							op.deleteString(newop.index - op.index, newop.length);
							newop.resize(0);
						}
						else {
							op.deleteString(newop.index - op.index, remain);
							newop.resize(newop.length - remain);
						}
						if (op.isNull()) {
							this.removeOperation(i);
							i--;
						}
						else
							this.fireOperationChanged(i);
						if (newop.isNull())
							return false;
					}
					else if (newop.index < op.index && newop.index+newop.length > op.index) {
						if (newop.index+newop.length >= op.index+op.length) {
							newop.resize(newop.length - op.length);
							this.removeOperation(i);
							i--;
						}
						else {
							var dlength:int = newop.index+newop.length - op.index;
							newop.resize(newop.length - dlength);
							op.deleteString(0, dlength);
							this.fireOperationChanged(i);
						}
					}
				}
				else if (newop.type == Operation.DOCUMENT_DELETE && op.type == Operation.DOCUMENT_DELETE) {
					if (newop.index == op.index) {
						op.resize(op.length + newop.length);
						this.fireOperationChanged(i);
						return false;
					}
					if (newop.index == (op.index - newop.length)) {
						op.index = op.index - newop.length;
						op.resize(op.length + newop.length);
						this.fireOperationChanged(i);
						return false;
					}
				}
				else if ((newop.type == Operation.WAVELET_ADD_PARTICIPANT && op.type == Operation.WAVELET_ADD_PARTICIPANT)
					|| (newop.type == Operation.WAVELET_REMOVE_PARTICIPANT && op.type == Operation.WAVELET_REMOVE_PARTICIPANT)) {
					if (newop.property == op.property)
						return false;
				}
			}
			this.insertOperation(i + 1, newop);
			return true;
		}

		/**
		 * Inserts an operation at the specified index.
		 * Fires signals appropriately.
		 * 
		 * @param index Position in operations list
		 * @param op Operation object to insert
		 */
		public function insertOperation(index:int, op:Operation):void
		{
			if (index > this.operations.length || index < 0)
				return;
			this.fireBeforeOperationsInserted(index, index);
			this.operations.addItemAt(op, index);
			this.fireAfterOperationsInserted(index, index);
		}		

		/**
		 * Removes the operation at the specified index.
		 * Fires signals appropriately.
		 *
		 * @param index Position in operations list
		 */
		public function removeOperation(index:int):void
		{
			if (index < 0 || index >= this.operations.length)
				return;
			this.fireBeforeOperationsRemoved(index, index);
			this.operations.removeItemAt(index);
			this.fireAfterOperationsRemoved(index, index);
		}
		
		/**
		 * Removes operations between and including the given start and end
		 * indexes. Fires signals appropriately.
		 */
		public function removeOperations(start:int, end:int, delete_obj:Boolean=true):void
		{
			if (start < 0 || end < 0 || start > end || start >= this.operations.length || end >= this.operations.length)
				return;
			this.fireBeforeOperationsRemoved(start, end);
			for (var index:int = start; start <= end; start++) {
				this.operations.removeItemAt(index);
			}
			this.fireAfterOperationsRemoved(start, end);
		}
		
		/**
		 * Updates the ID of operations on temporary Blips.
		 */
		public function updateBlipId(tempId:String, blipId:String):void
		{
			for (var i:int = 0; i < this.operations.length; i++) {
				var op:Operation = this.operations.getItemAt(i) as Operation;
				if (op.blipId == tempId) {
					op.blipId = blipId;
					this.fireOperationChanged(i);
				}
			}
		}
			
		/**
		 * Prevents the Operations on the Blip with the given ID from being
		 * handed over via fetch().
		 */
		public function lockBlipOps(blipId:String):void
		{
			if (!this.lockedBlips.contains(blipId))
				this.lockedBlips.addItem(blipId);
		}
		
		/**
		 * Allows the Operations on the Blip with the given ID from being
		 * handed over via fetch().
		 */
		public function unlockBlipOps(blipId:String):void
		{
			if (!this.lockedBlips.contains(blipId))
			{
				trace('Trying to unlock non exisiting blip.');
				return;
			}
			var index:int = this.lockedBlips.getItemIndex(blipId);
			
			this.lockedBlips.removeItemAt(index);
		}		
		
		private function fireOperationChanged(index:int):void
		{
			this.dispatchEvent(new OperationChangedEvent(index));
		}
        
        private function fireBeforeOperationsInserted(start:int, end:int):void 
        {
			this.dispatchEvent(new OperationsEvent(OperationsEvent.BEFORE_OPERATIONS_INSERTED, start, end));
        }
        
        private function fireAfterOperationsInserted(start:int, end:int):void
		{
            this.dispatchEvent(new OperationsEvent(OperationsEvent.AFTER_OPERATIONS_INSERTED, start, end));
        }

		private function fireBeforeOperationsRemoved(start:int, end:int):void 
		{
			this.dispatchEvent(new OperationsEvent(OperationsEvent.BEFORE_OPERATIONS_REMOVED, start, end));
		}
		
		private function fireAfterOperationsRemoved(start:int, end:int):void 
		{
			this.dispatchEvent(new OperationsEvent(OperationsEvent.AFTER_OPERATIONS_REMOVED, start, end));
		}
	}
}
