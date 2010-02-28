/**
 *
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.codehaus.stomp.headers
{
	public class ConnectHeaders extends Headers
	{
		/**
		 * Specifies the JMS Client ID which is used in combination with the activemq.subcriptionName 
		 * to denote a durable subscriber.
		 **/
		public static const CLIENT_ID : String = "client-id";
		
		public static const LOGIN : String = "login";
		
		public static const PASSCODE : String = "passcode";
		
		/**
		 *  RabbitMQ/AMQP only
		 */
		public static const VIRTUAL_HOST: String = "virtual-host";
		
		/**
		 *  RabbitMQ/AMQP only
		 */
		public static const REALM: String = "realm";
		
		
		public function set clientID (id : String) : void
		{
			addHeader(CLIENT_ID, id);
		}
		
		public function set login(username: String) : void
		{
			addHeader(LOGIN, username);
		}
		
		public function set passcode(password: String) : void
		{
			addHeader(PASSCODE, password);
		}

		public function set virtualHost(hostname: String) : void
		{
			addHeader(VIRTUAL_HOST, hostname);
		}
	
		public function set realm(realm: String) : void
		{
			addHeader(REALM, realm);
		}					
		
	}
}