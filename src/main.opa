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

type author = { system } / { author : string }
type message = {
  author : author;
  text : string;
  date : Date.date;
  event : string;
}

github_url = "https://github.com/Aqua-Ye/OpaChat"

db /history : list(message)

room = Network.cloud("room") : Network.network(message)

user_update(x: message) =
  line = <div class="line {x.event}">
            <span class="date">{Date.to_string_time_only(x.date)}</span>
            { match x.author with
              | {system} -> <span class="system"/>
              | {~author} -> <span class="user">{author}</span> }
            <span class="message">{x.text}</span>
         </div>
  do Dom.transform([#conversation +<- line])
  Dom.scroll_to_bottom(Dom.select_body())

broadcast(author, class, text) =
  message = {~author ~text date=Date.now() event=class}
  do Network.broadcast(message, room)
  do /history <- [message | /history]
  Dom.clear_value(#entry)

build_page(header, content) =
  <div id=#header><div id=#logo/>{header}</div>
  <div id=#content>{content}</div>

launch(author) =
  init_client() =
    history = List.rev(List.take(20, /history))
    // FIXME: optimize this...
    do List.iter(user_update, history)
    Network.add_callback(user_update, room)
   send_message() =
     broadcast({~author}, "", Dom.get_value(#entry))
   logout() =
     do broadcast({system}, "leave", "{author} has left the room")
     Client.goto("/")
   build_page(
     <a class="button github" href="{github_url}" target="_blank">Fork me on GitHub !</a>
     <span class="button" onclick={_ -> logout()}>Logout</span>,
     <div id=#conversation onready={_ -> init_client()}/>
     <div id=#chatbar>
       <input id=#entry onnewline={_ -> send_message()}/>
       <span class="button" onclick={_ -> send_message()}>Send</span>
     </div>
   ) |> Xhtml.add_onready(_ -> Dom.give_focus(#entry), _)

start() =
   go(_) =
     do Dom.transform([#main <- <>Loading...</>])
     author = Dom.get_value(#author)
     do Dom.transform([#main <- launch(author)])
     broadcast({system}, "join", "{author} is connected to the room")
   <div id=#main>{
     build_page(
       <></>,
       <span>Choose your name: </span><input id=#author onnewline={go}/>
       <span class="button" onclick={go}>Join</span>
     )
   }</div> |> Xhtml.add_onready(_ -> Dom.give_focus(#author), _)

server = Server.one_page_bundle("Chat",
       [@static_resource_directory("resources")],
       ["resources/style.css"], start)
