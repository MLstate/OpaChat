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

import stdlib.core.date
import stdlib.web.client
import stdlib.system

GITHUB_URL = "https://github.com/Aqua-Ye/OpaChat"

type user = (int, string)
type author = { system } / { author : user }
type message = {
  author : author
  text : string
  date : Date.date
  event : string
}
type msg = {message : message} / {connection : user} / {disconnection : user}

db /history : intmap(message)

@publish room = Network.cloud("room") : Network.network(msg)

// @client
// ping(fun)=
//   Scheduler.timer(15000, fun)

// manage_users(user_list : stringmap(Date.date), action : users_action) =
//   clean(key, value, acc) =
//     time = Duration.in_seconds(Duration.between(value, Date.now()))
//     if time > 20. then
//        do broadcast({system}, "leave", "{key} has left the room (timeout)")
//        acc
//     else
//        Map.add(key, value, acc)


//   match action with
//    | {add = u} ->       newmap = Map.add(u, Date.now(),user_list)
//                         do broadcast({system}, "join", "{u} is connected to the room")
//                         do Network.broadcast({users = newmap}, room)
//                         {set = newmap}

//    | {remove = u} ->    newmap = Map.remove(u, user_list)
//                         do broadcast({system}, "leave", "{u} has left the room (quit)")
//                         do Network.broadcast({users = newmap}, room)
//                         {set = newmap}

//    | {clean} ->         newmap = Map.fold(clean, user_list, Map.empty)
//                         do Network.broadcast({users = newmap}, room)
//                         {set = newmap}

//    | {ping = u} ->      temp = Map.remove(u, user_list)
//                         {set = Map.add(u, Date.now(), temp)}

// users = Session.cloud("users", Map.empty, manage_users)

// do Scheduler.timer(10000, ( -> Session.send(users, {clean})))

launch_date = Date.now()

update_stats(mem) =
  uptime_duration = Date.between(launch_date, Date.now())
  uptime = Date.of_duration(uptime_duration)
  uptime = Date.shift_backward(uptime, Date.to_duration(Date.milliseconds(3600000))) // 1 hour shift
  do Dom.transform([#uptime <- <>Uptime: {Date.to_string_time_only(uptime)}</>])
  do Dom.transform([#memory <- <>Memory: {mem} Mo</>])
  void

@client
user_update(mem:int)(msgs:list(msg)) =
  do update_stats(mem)
  List.iter(msg->
    match msg with
     | {message = x} ->
      line = <div class="line {x.event}">
                <span class="date">{Date.to_string_time_only(x.date)}</span>
                { match x.author with
                  | {system} -> <span class="system"/>
                  | {~author} -> <span class="user">{author.f2}</span> }
                <span class="message">{x.text}</span>
             </div>
      do Dom.transform([#conversation +<- line])
      do Dom.set_scroll_top(Dom.select_window(), Dom.get_scrollable_size(#content).y_px)
      void
     _ -> void
    //  | ~{users} -> list = Map.fold((elt, _, acc -> <>{acc}<li>{elt}</li></>), users, <></>)
    //                Dom.transform([#user_list <- <ul>{list}</ul>])
  , msgs)

//@server
broadcast(author, event, text) =
  message = {~author ~text date=Date.now() ~event}
  do /history[?] <- message
  Network.broadcast({message = message}, room)

build_page(header, content) =
  <div id=#header>
    <div id=#logo/>
    <div>{header}</div>
  </div>
  <div id=#content>{content}</div>

@client
send_message(broadcast) =
  _ = broadcast("", Dom.get_value(#entry))
  Dom.clear_value(#entry)

do_logout(user)(_) =
  _ = Network.broadcast({disconnection=user}, room)
  //do Session.send(users, {remove=author})
  Client.goto("/")

@client
do_broadcast(broadcast)(_) = send_message(broadcast)

@server
observe(msg) =
  match msg
  {connection=user} -> do jlog("connection {user}") void
  {disconnection=user} -> do jlog("disconnection {user}") void
  _ -> user_update(System.get_memory_usage()/(1024*1024))([msg])

@server
inform(user)() = do jlog("auto disconnection {user}") void

init_client(user) =
  //do Session.send(users, {add=author})
  //do ping( -> Session.send(users, {ping=author}))
  obs = Network.observe_and_inform(observe, inform(user), room)
  _ = Network.broadcast({connection=user}, room)
  do Dom.bind_beforeunload_confirmation(_ ->
    do Network.broadcast({disconnection=user}, room)
    do Network.unobserve(obs)
    {none}
  )
  history_list = IntMap.To.val_list(/history)
  len = List.length(history_list)
  history = List.drop(len-20, history_list)
  do user_update(0)(List.map(a->{message = a}, history))
  do update_stats(System.get_memory_usage()/(1024*1024))
  void

launch_chat(author:string) =
  user = (Random.int(65536), author)
  broadcast = broadcast({author=user}, _, _)
  build_page(
    <a class="button github" href="{GITHUB_URL}" target="_blank">Fork me on GitHub !</a>
    <span class="button" onclick={do_logout(user)}>Logout</span>,
    <div id=#conversation onready={_ -> init_client(user)}/>
    <div id=#user_list/>
    <div id=#stats><span id=#users/><span id=#uptime/><span id=#memory/></div>
    <div id=#chatbar>
      <input id=#entry onready={_ -> Dom.give_focus(#entry)} onnewline={do_broadcast(broadcast)}/>
      <span class="button" onclick={do_broadcast(broadcast)}>Send</span>
    </div>
  )

@client
do_join(launch)(_) =
  Dom.transform([
    #main <- <>Loading chat...</>,
    #main <- launch(Dom.get_value(#author))]
  )

main() =
  <div id=#main>{
    build_page(
      <h1>Wecome to OpaChat</h1>,
      <span>Choose your name: </span>
      <input id=#author onready={_ -> Dom.give_focus(#author)} onnewline={do_join(launch_chat)}/>
      <span class="button" onclick={do_join(launch_chat)}>Join</span>
    )
  }</div>

server =
  Server.one_page_bundle(
    "OpaChat - a chat in Opa",
    [@static_resource_directory("resources")], // include resources directory
    ["resources/style.css"],
    main
  )
