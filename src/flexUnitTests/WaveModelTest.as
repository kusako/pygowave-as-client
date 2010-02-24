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
	import com.adobe.utils.DictionaryUtil;
	
	import flash.utils.Dictionary;
	
	import flexunit.framework.TestCase;
	
	import mx.collections.ArrayCollection;
	import pygowave.model.Wavelet;
	import pygowave.model.WaveModel;
	
	public class WaveModelTest extends TestCase
	{
		// please note that all test methods should start with 'test' and should be public
		
		// Reference declaration for class to test
		private var waveModel : WaveModel;
		
		public function WaveModelTest(methodName:String=null)
		{
			//TODO: implement function
			super(methodName);
		}
		
		//This method will be called before every test function
		override public function setUp():void
		{
			//TODO: implement function
			super.setUp();
			this.waveModel = new WaveModel('waveId', 'viewerId', null);
		}
		
		//This method will be called after every test function
		override public function tearDown():void
		{
			//TODO: implement function
			super.tearDown();
		}
		

		public function testSampleMethod():void
		{
			assertEquals('waveId', this.waveModel.waveId);
			this.waveModel.createWavelet('waveletId', null, 'title', true, new Date(), new Date(), 0);
			assertEquals(1, DictionaryUtil.getKeys(this.waveModel.wavelets).length);
			var wavelet:Wavelet = this.waveModel.rootWavelet;
			assertNotNull(wavelet);
			wavelet.appendBlip(null, 'Test', new ArrayCollection(), null, new Dictionary(), true, new Date(), 0, false);
			assertNotNull(wavelet.allBlipIDs().length == 1);
			assertEquals('TBD_01', wavelet.allBlipIDs().getItemAt(0));
			this.waveModel.removeWavelet('waveletId');
			assertEquals(0, DictionaryUtil.getKeys(this.waveModel.wavelets).length);			
		}
	}
}