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

type user = (int, string) // user_id, user_name
type author = { system } / { author : user }
type message = {
  author : author
  text : string
  date : Date.date
  event : string
}
type client_channel = channel(void)
type msg = {message : message} / {connection : (user, client_channel)} / {disconnection : (user, client_channel)} / {stats}

db /history : intmap(message)

@publish room = Network.cloud("room") : Network.network(msg)

@private users = Mutable.make([]) : Mutable.t(list(user))

@private launch_date = Date.now()

@server
server_observe(message) =
  match message
  {connection=(user, client_channel)} ->
    do users.set(List.add(user, users.get()))
    do Network.broadcast({stats}, room)
    do Session.on_remove(client_channel, (->
      do server_observe({disconnection=(user, client_channel)})
      void
    ))
    void
  {disconnection=(user, _client_channel)} ->
    do users.set(List.remove(user, users.get()))
    do Network.broadcast({stats}, room)
    void
  _ -> void

@server
_ = Network.observe(server_observe, room)

@client
update_stats((uptime, mem)) =
  do Dom.transform([#uptime <- <>Uptime: {Date.to_string_time_only(uptime)}</>])
  do Dom.transform([#memory <- <>Memory: {mem} Mo</>])
  void

@client
update_users(nb_users, users) =
  do Dom.transform([#users <- <>Users: {nb_users}</>])
  do Dom.transform([#user_list <- <ul>{users}</ul>])
  void

@client
message_update(stats)(messages:list(message)) =
  do update_stats(stats)
  do List.iter(message->
    line = <div class="line {message.event}">
              <span class="date">{Date.to_string_time_only(message.date)}</span>
              { match message.author with
                | {system} -> <span class="system"/>
                | {~author} -> <span class="user">{author.f2}</span> }
              <span class="message">{message.text}</span>
           </div>
    do Dom.transform([#conversation +<- line])
    void
  , messages)
  Dom.set_scroll_top(Dom.select_window(), Dom.get_scrollable_size(#content).y_px)

@server
broadcast(author, event, text) =
  message = {~author ~text date=Date.now() ~event}
  do /history[?] <- message
  Network.broadcast({message = message}, room)

@server
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

@client
do_broadcast(broadcast)(_) = send_message(broadcast)

@server
mem() = System.get_memory_usage()/(1024*1024)

compute_stats() =
  uptime_duration = Date.between(launch_date, Date.now())
  uptime = Date.of_duration(uptime_duration)
  uptime = Date.shift_backward(uptime, Date.to_duration(Date.milliseconds(3600000))) // 1 hour shift
  (uptime, mem())

@server
client_observe(msg) =
  match msg
  {~message} -> message_update(compute_stats())([message])
  {stats} ->
    do update_stats(compute_stats())
    users = users.get()
    users_html_list = List.fold((elt, acc -> <><li>{elt.f2}</li>{acc}</>), users, <></>)
    do update_users(List.length(users), users_html_list)
    void
  _ -> void

@server
init_client(user, client_channel) =
  obs = Network.observe(client_observe, room)
  _ = Network.broadcast({connection=(user, client_channel)}, room)
  do Dom.bind_beforeunload_confirmation(_ ->
    do Network.broadcast({disconnection=(user, client_channel)}, room)
    do Network.unobserve(obs)
    {none}
  )
  history_list = IntMap.To.val_list(/history)
  len = List.length(history_list)
  history = List.drop(len-20, history_list)
  do message_update(compute_stats())(history)
  void

@server
launch_chat(user:user, client_channel) =
  broadcast = broadcast({author=user}, _, _)
  build_page(
    <a class="button github" href="{GITHUB_URL}" target="_blank">Fork me on GitHub !</a>,
    <div id=#conversation onready={_ -> init_client(user, client_channel)}/>
    <div id=#user_list/>
    <div id=#stats><span id=#users/><span id=#uptime/><span id=#memory/></div>
    <div id=#chatbar>
      <input id=#entry onready={_ -> Dom.give_focus(#entry)} onnewline={do_broadcast(broadcast)}/>
      <span class="button" onclick={do_broadcast(broadcast)}>Send</span>
    </div>
  )

@client
do_join(user_id, launch)(_) =
  user = (user_id, Dom.get_value(#author))
  client_channel = Session.make_callback(ignore)
  Dom.transform([
    #main <- <>Loading chat...</>,
    #main <- launch(user, client_channel)
  ])

@server
main() =
  user_id = Random.int(65536) // a user identifier
  <div id=#main>{
    build_page(
      <h1>Wecome to OpaChat</h1>,
      <span>Choose your name: </span>
      <input id=#author onready={_ -> Dom.give_focus(#author)} onnewline={do_join(user_id, launch_chat)}/>
      <span class="button" onclick={do_join(user_id, launch_chat)}>Join</span>
    )
  }</div>

server =
  Server.one_page_bundle(
    "OpaChat - a chat built with Opa",
    [@static_resource_directory("resources")], // include resources directory
    ["resources/style.css"], // web application CSS
    main
  )
