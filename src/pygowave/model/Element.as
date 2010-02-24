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
	
	public class Element extends EventDispatcher
	{
		public var id:String;
		public var blip:Blip;
		public var position:int;
		
		public static const GADGET:String = 'gadget';
		
		public function Element(arg01:Object, arg02:Object, arg03:Object, arg04:Object, arg05:Object, target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public function applyDelta(delta:Object):void
		{
			// TODO
		}
		
		public function setUserPref(key:String, value:String, noevent:Boolean):void
		{
			// TODO
		}
	}
}