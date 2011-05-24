/*  A simple, one-room, scalable real-time web chat

    Copyright (C) 2010-2011  MLstate

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import stdlib.{date}

type message = { author: string /**The name of the author (arbitrary string)*/
               ; text: string  /**Content entered by the user*/
               ; date: Date.date
               }

db /history : list(message)

room = Network.cloud("room"): Network.network(message)

user_update(x: message) =
  line = <div class="line">
            <span class="date">{Date.to_string_time_only(x.date)}</span>
            <span class="user">{x.author}:</span>
            <span class="message">{x.text}</span>
         </div>
  do Dom.transform([#conversation +<- line ])
  Dom.scroll_to_bottom(#conversation)

broadcast(author) =
   message = {~author text=Dom.get_value(#entry) date=Date.now()}
   do Network.broadcast(message, room)
   do /history <- [message | /history]
   Dom.clear_value(#entry)

launch(author) =
   init_client() =
     history = List.take(20, /history)
     do List.iter(user_update, history)
     Network.add_callback(user_update, room)
   <div id=#header><div id=#logo></div></div>
   <div id=#conversation onready={_ -> init_client()}></div>
   <input id=#entry  onnewline={_ -> broadcast(author)}/>
   <div class="button" onclick={_ -> broadcast(author)}>Send</div>

start() =
   go(ev) = Dom.transform([#main <- launch(Dom.get_value(#author))])
   <div id=#main>
   <div id=#header><div id=#logo></div>Choose your name:</div>
   <input id=#author onnewline={go}/>
   <div class="button" onclick={go}>Launch</div>
   </div>

server = Server.one_page_bundle("Chat",
       [@static_resource_directory("resources")],
       ["resources/css.css"], start)
