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

db /history : intmap(message)

room = Network.cloud("room") : Network.network(message)

update_stats() = void

@client
user_update(x: message) =
  line = <div class="line {x.event}">
            <span class="date">{Date.to_string_time_only(x.date)}</span>
            { match x.author with
              | {system} -> <span class="system"/>
              | {~author} -> <span class="user">{author}</span> }
            <span class="message">{x.text}</span>
         </div>
  do Dom.transform([#conversation +<- line])
  do Dom.set_scroll_top(Dom.select_window(), Dom.get_scrollable_size(#content).y_px)
  void

broadcast(author, event, text) =
  message = {~author ~text date=Date.now() ~event}
  do /history[?] <- message
  //do /history <- [message | /history]
  Network.broadcast(message, room)

build_page(header, content) =
  <div id=#header><div id=#logo/>{header}</div>
  <div id=#content>{content}</div>

@client
send_message(broadcast) =
  _ = broadcast("", Dom.get_value(#entry))
  Dom.clear_value(#entry)

launch(author:author) =
  init_client() =
    history_list = IntMap.To.val_list(/history)
    len = List.length(history_list)
    history = List.drop(len-20, history_list)
    // FIXME: optimize this...
    do List.iter(user_update, history)
    Network.add_callback(user_update, room)
   logout() =
     do broadcast({system}, "leave", "{author} has left the room")
     Client.goto("/")
   do_broadcast = broadcast(author, _, _)
   build_page(
     <a class="button github" href="{github_url}" target="_blank">Fork me on GitHub !</a>
     <span class="button" onclick={_ -> logout()}>Logout</span>,
     <div id=#conversation onready={_ -> init_client()}/>
     <div id=#stats><div id=#users/><div id=#uptime/><div id=#memory/></div>
     <div id=#chatbar onready={_ -> Dom.give_focus(#entry)}>
       <input id=#entry onnewline={_ -> send_message(do_broadcast)}/>
       <span class="button" onclick={_ -> send_message(do_broadcast)}>Send</span>
     </div>
   )

load(broadcast) =
  author = Dom.get_value(#author)
  do Dom.transform([#main <- <>Loading...</>])
  do Dom.transform([#main <- launch(~{author})])
  broadcast("join", "{author} is connected to the room")

start() =
   <div id=#main onready={_ -> Dom.give_focus(#author)}>{
     build_page(
       <></>,
       <span>Choose your name: </span>
       <input id=#author onnewline={_ -> load(broadcast({system}, _, _))}/>
       <span class="button" onclick={_ -> load(broadcast({system}, _, _))}>Join</span>
     )
   }</div>

server = Server.one_page_bundle("Chat",
       [@static_resource_directory("resources")],
       ["resources/style.css"], start)
