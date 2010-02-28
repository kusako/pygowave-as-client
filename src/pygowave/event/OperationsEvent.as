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
package pygowave.event
{
	import flash.events.Event;
	
	public class OperationsEvent extends Event
	{
		public static const BEFORE_OPERATIONS_INSERTED:String = 'beforeOperationsInserted';
		public static const AFTER_OPERATIONS_INSERTED:String = 'afterOperationsInserted';
		public static const BEFORE_OPERATIONS_REMOVED:String = 'beforeOperationsRemoved';
		public static const AFTER_OPERATIONS_REMOVED:String = 'afterOperationsRemoved';
		
		public var start:int;
		public var end:int;
		
		public function OperationsEvent(type:String, start:int, end:int, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.start = start;
			this.end = end;
		}
	}
}