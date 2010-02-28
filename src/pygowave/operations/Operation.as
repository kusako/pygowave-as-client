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
	

	/**
	 * Represents a generic operation applied on the server.
     *	
	 * This operation class contains data that is filled in depending on the
	 * operation type.
	 *
	 * It can be used directly, but doing so will not result
	 * in local, transient reflection of state on the blips. In other words,
	 * creating a "delete blip" operation will not remove the blip from the local
	 * context for the duration of this session. It is better to use the OpBased
	 * model classes directly instead.
	 */	
	public class Operation
	{
		public static const DOCUMENT_NOOP:String = 'DOCUMENT_NOOP';
		public static const	DOCUMENT_INSERT:String = 'DOCUMENT_INSERT';
		public static const	DOCUMENT_DELETE:String = 'DOCUMENT_DELETE';
		public static const	DOCUMENT_ELEMENT_INSERT:String = 'DOCUMENT_ELEMENT_INSERT';
		public static const	DOCUMENT_ELEMENT_DELETE:String = 'DOCUMENT_ELEMENT_DELETE';
		public static const	DOCUMENT_ELEMENT_DELTA:String = 'DOCUMENT_ELEMENT_DELTA';
		public static const	DOCUMENT_ELEMENT_SETPREF:String = 'DOCUMENT_ELEMENT_SETPREF';
		public static const	WAVELET_ADD_PARTICIPANT:String = 'WAVELET_ADD_PARTICIPANT';
		public static const	WAVELET_REMOVE_PARTICIPANT:String = 'WAVELET_REMOVE_PARTICIPANT';
		public static const	WAVELET_APPEND_BLIP:String = 'WAVELET_APPEND_BLIP';
		public static const	BLIP_CREATE_CHILD:String = 'BLIP_CREATE_CHILD';
		public static const	BLIP_DELETE:String = 'BLIP_DELETE';
		
		public var type: String;
		public var waveId: String;
		public var waveletId: String;
		public var index: int;
		public var property: Object;
		public var blipId: String;
		
		/**
		 * Constructs this operation with contextual data.
		 *
		 * @param opType Type of operation
		 * @param waveId The id of the wave that this operation is to
		 * be applied.
		 * @param waveletId The id of the wavelet that this operation is
		 * to be applied.
		 * @param blipId The optional id of the Blip that this
		 * operation is to be applied.
		 * @param index Optional integer index for content-based
		 * operations.
		 * @param prop A weakly typed property object is based
		 * on the context of this operation.
		 */
		public function Operation(opType:String, waveId:String, waveletId:String, blipId:String = '', index:int = -1, prop:Object = null)
		{
			this.type = opType;
			this.waveId = waveId;
			this.waveletId = waveletId;
			this.blipId = blipId;
			this.index = index;
			this.property = prop;
		}

		/**
		 * Create a copy of this operation.
		 * @return Copy of this operation.
		 */
		public function clone():Operation
		{
			return new Operation(this.type, this.waveId, this.waveletId, this.blipId, this.index, this.property);
		}
		
		/**
		 * Return whether this operation is a null operation i.e. it does not
		 * change anything.
		 */
		public function isNull():Boolean
		{
			if (this.type == DOCUMENT_INSERT)
			{
				return (this.length == 0);
			}
			else if (this.type == DOCUMENT_DELETE)
			{
				return (int(this.property) == 0);	
			}
			else
			{
				return false;
			}
		}

		/**
		 * Returns if this operation is compatible to another one i.e. it could potentially influence
		 * the other operation.
		 */
		public function isCompatibleTo(other:Operation):Boolean
		{
			if (this.waveId != other.waveId || this.waveletId != other.waveletId || this.blipId != other.blipId) 
			{
				return false;	
			}
			else 
			{
				return true;
			}
		}
		
		/**
		 * Returns true, if this op is an insertion operation.
		 */		
		public function isInsert():Boolean
		{
			return ((this.type == DOCUMENT_INSERT) || (this.type == DOCUMENT_ELEMENT_INSERT));
		}
		
		/**
		 * Returns true, if this op is a deletion operation.
		 */
		public function isDelete():Boolean
		{
			return ((this.type == DOCUMENT_DELETE) || (this.type == DOCUMENT_ELEMENT_DELETE));
		}
		
		/**
		 * Returns true, if this op is an (attribute) change operation.
		 */
		public function isChange():Boolean
		{
			return ((this.type == DOCUMENT_ELEMENT_DELTA)||(this.type == DOCUMENT_ELEMENT_SETPREF));
		}
		
		/**
		 * Returns the length of this operation.
		 * This can be interpreted as the distance a concurrent operation's index
		 * must be moved to include the effects of this operation.
		 */
		public function get length():int
		{
			if (this.type == DOCUMENT_INSERT) 
			{
				// FIXME null??
				return this.property.toString().length;
			}
			else if (this.type == DOCUMENT_DELETE)
			{
				return int(this.property);
			}
			else if (type == DOCUMENT_ELEMENT_INSERT || type == DOCUMENT_ELEMENT_DELETE)
			{
				return 1;
			}
			else
			{
				return 0;
			}
		}
		
		/**
		 * Delete operations: Sets the amount of deleted characters/elements to
		 * a value.
		 *
		 * Other operations: No effect.
		 */
		public function resize(value:int):void
		{
			if (this.type == DOCUMENT_DELETE)
			{
				this.property = (value > 0 ? value : 0);
			}
		}
		
		/**
		 * DOCUMENT_INSERT: Inserts the string \a s into the property at
		 * the specified \a position.
		 *
		 * Other operations: No effect.
		 */
		public function insertString(pos:int, s:String):void
		{
			if (this.type == DOCUMENT_INSERT)
			{
				var propAsString:String = this.property.toString();
				// TODO Test this...
				this.property = propAsString.slice(0, pos) + s + propAsString.slice(pos, propAsString.length);
			}
		}
		
		/**
		 * DOCUMENT_INSERT: Deletes a substring at \a pos with the specified
		 * length from the property.
		 *
		 * Other operations: No effect.
		 */
		public function deleteString(pos:int, length:int):void
		{
			if (this.type == DOCUMENT_INSERT) 
			{
				var propAsString:String = this.property.toString();
				this.property = propAsString.slice(0, pos) + propAsString.slice(pos + length, propAsString.length);
			}
		}
		
		/**
		 * Serialize this operation into a dictionary. Official robots API format.
		 */
		public function serialize():Object
		{
			var result:Object = new Object();
			result.type = this.type;
			result.waveId = this.waveId;
			result.waveletId = this.waveletId;
			result.blipId = this.blipId;
			result.index = this.index;
			result.property = this.property;
			
			return result;
		}
		
		/**
		 * Unserialize an operation from a dictionary.
		 */
		public static function unserialize(obj:Object):Operation
		{
			return new Operation(obj.type, obj.waveId, obj.waveletId, obj.blipId, obj.index, obj.property);
		}

		/**
		 *  
		 * @return String representation of this operation.
		 * 
		 */		
		public function toString():String
		{
			return this.type.toLowerCase() + '("' + blipId + '",' + this.index + ',' + this.property.toString() + ')';
			
		}
	}
}