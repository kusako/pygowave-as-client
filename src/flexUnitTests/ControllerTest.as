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
package flexUnitTests
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import flexunit.framework.TestCase;
	import pygowave.model.Wavelet;
	import pygowave.controller.Controller;
	
	public class ControllerTest extends TestCase
	{
		// please note that all test methods should start with 'test' and should be public
		private var c:Controller;
		
		public function ControllerTest(methodName:String=null)
		{
			//TODO: implement function
			super(methodName);
		}
		
		//This method will be called before every test function
		override public function setUp():void
		{
			//TODO: implement function
			super.setUp();
			this.c = new Controller();
		}
		
		//This method will be called after every test function
		override public function tearDown():void
		{
			//TODO: implement function
			super.tearDown();
		}
		
		/* sample test method
		public function testSampleMethod():void
		{
		// Add your test logic here
		fail("Test method Not yet implemented");
		}
		*/
		
		public function testConnect():void
		{
			c.connectToHost('192.168.56.3', 'root', 'pygowave');
			
			var t:Timer = new Timer(5000);
			t.addEventListener(TimerEvent.TIMER, addAsync(connectTimedOut, 6000));
			t.start();
		}
		
		private function connectTimedOut(event:Event):void
		{
			assertEquals('online', c.state);
			for each (var wavelet:Wavelet in c.allWaveletColl)
			{
				trace(wavelet.id);
			}
			c.openWavelet(c.allWaveletColl.getItemAt(0).id);
			var t:Timer = new Timer(1000);
			t.addEventListener(TimerEvent.TIMER, addAsync(openTimedOut, 2000));
			t.start();
			
		}
		
		private function openTimedOut(event:Event):void
		{
			trace('opened');
			for each (var waveletId:String in c.openWavelets) {
				trace (waveletId);
			}
			
			c.disconnectFromHost();
		}
	}
}