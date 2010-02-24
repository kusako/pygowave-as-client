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
package pygowave.event
{
	import flash.events.Event;
	
	public class OperationChangedEvent extends Event
	{
		public static const OPERATION_CHANGED_EVENT:String = 'operationChanged';
		
		public var index:int;
		
		public function OperationChangedEvent(index:int, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(OPERATION_CHANGED_EVENT, bubbles, cancelable);
			this.index = index;
		}
	}
}