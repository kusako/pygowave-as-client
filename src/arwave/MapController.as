/*
* This file is part of the ARWave FLEX Client
*
* Copyright (C) 2010 Markus Strickler <markus.strickelr@googlemail.com>
*
* This program is free software: you can redistribute it and/or
* modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of
* the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; see the file COPYING. If not,
* see <http://www.gnu.org/licenses/>.
*/
package arwave
{
	import com.google.maps.LatLng;
	import com.google.maps.Map;
	import com.google.maps.MapMouseEvent;
	import com.google.maps.overlays.Marker;
	import com.google.maps.overlays.MarkerOptions;
	
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.PropertyChangeEvent;
	
	import pygowave.controller.Controller;
	import pygowave.model.Blip;

	/**
	 * Google Maps Controller class.
	 * Handles conversion between AR enabled Blips and Google map markers.
	 * 
	 */
	public class MapController
	{
		
		public var markers:Dictionary;
		public var map:Map;
		public var blips:ArrayCollection;
		private var wc:Controller;
		
		public function MapController(wc:Controller)
		{
			this.markers = new Dictionary();
			this.wc = wc;
			
		}

		public function registerBlipCollection(blips:ArrayCollection):void
		{
			this.blips = blips;
			blips.addEventListener(CollectionEvent.COLLECTION_CHANGE, onBlipsChanged);
		}

		public function resetMarkers():void
		{
			if (blips != null)
			{
				blips.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onBlipsChanged);
			}
				
			for each (var m:Marker in this.markers)
			{
				map.removeOverlay(m);
			}
			markers = new Dictionary();
		}
		
		protected function parseLocation(content:String):LatLng
		{
			var splitContent:Array = content.split('#');
			var result:LatLng = null;
			
			if (splitContent.length >= 2)
			{
				result = new LatLng(splitContent[0], splitContent[1]);	
			}
			else
			{
				result = new LatLng(0, 0);
			}
			
			return result;
		}
		
		private function marker_onDragEnd(event:MapMouseEvent):void
		{
			for (var blip:Object in markers)
			{
				var marker:Marker = markers[blip];
				if (marker == event.target)
				{
					var splitContent:Array = blip.content.split('#');
					var newContent:String = this.locationToString(marker.getLatLng()) + splitContent[splitContent.length - 1]
					wc.textDeleted(blip.wavelet.id, blip.id, 0, blip.content.length);
					wc.textInserted(blip.wavelet.id, blip.id, 0, newContent);					
					blip.content = this.locationToString(marker.getLatLng()) + splitContent[splitContent.length - 1];
				}
			}
		}
		
		private function locationToString(location:LatLng):String
		{
			return location.lat() + '#' + location.lng() + '#0#';	
		}
		
		private function onBlipsChanged(event:CollectionEvent):void
		{
			var location:LatLng;
			var marker:Marker;
			var blip:Blip;
			switch(event.kind)
			{
				case CollectionEventKind.ADD:
					for each (blip in event.items)
					{						
						location = this.parseLocation(blip.content);
						marker = new Marker(location, new MarkerOptions({draggable: true}));
						markers[blip] = (marker);
						marker.addEventListener(MapMouseEvent.DRAG_END, marker_onDragEnd);
						map.addOverlay(marker);
					}
					break;
				case CollectionEventKind.REMOVE:
					for each (blip in event.items)
					{
						if (markers[blip])
						{
							map.removeOverlay(markers[blip] as Marker);
							delete markers[blip];
						}
					}
					break;
				case CollectionEventKind.RESET:
					for each (var m:Marker in this.markers)
					{
						map.removeOverlay(m);
					}
					markers = new Dictionary();
					break;
				case CollectionEventKind.UPDATE:
					for each (var updateEvent:PropertyChangeEvent in event.items)
					{
						if (updateEvent.property == 'content')
						{
							blip = updateEvent.source as Blip;
							marker = markers[blip];
							marker.setLatLng(this.parseLocation(blip.content));
						}
					}
					break;
			}
		}
	}
}