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
import stdlib.widgets.bootstrap

/** Constants **/

GITHUB_USER = "Aqua-Ye"
GITHUB_REPO = "OpaChat"
NB_LAST_MSGS = 10

/** Types **/

type user = {
  int id,
  string name
}
type source = { system } or { user user }
type message = {
  source source,
  string text,
  Date.date date,
}
type client_channel = channel(void)
type network_msg =
   {message message}
or {(user, client_channel) connection}
or {user disconnection}
or {stats}

/** Database **/

database intmap(message) /history

exposed Network.network(network_msg) room = Network.cloud("room")
private reference(list(user)) users = ServerReference.create([])
private launch_date = Date.now()

/** Page **/

function build_page(header, content) {
  <div id=#header>
    <img src="/resources/img/opa-cloud-logo.png"/>
    {header}
  </div>
  <div id=#content>{content}</div>
}

/** Connection **/

server function server_observe(message) {
  match (message) {
  case {connection:(user, client_channel)} :
    ServerReference.update(users, List.add(user, _))
    Network.broadcast({stats}, room)
    Session.on_remove(client_channel, function() {
      server_observe({disconnection:user})
    })
  case {disconnection:user} :
    ServerReference.update(users, List.remove(user, _))
    Network.broadcast({stats}, room)
  default: void
  }
}

_ = Network.observe(server_observe, room)

/** Stats **/

server function mem() {
  System.get_memory_usage()/(1024*1024)
}

function compute_stats() {
  uptime_duration = Date.between(launch_date, Date.now())
  uptime = Date.of_duration(uptime_duration)
  uptime = Date.shift_backward(uptime, Date.to_duration(Date.milliseconds(3600000))) // 1 hour shift
  (uptime, mem())
}

client function update_stats((uptime, mem)) {
  #uptime = <>Uptime: {Date.to_string_time_only(uptime)}</>
  #memory = <>Memory: {mem} Mo</>
}

client function update_users(nb_users, users) {
  #users = <>Users: {nb_users}</>
  #user_list = <ul>{users}</ul>
}

/** Conversation **/

client function message_update(stats, list(message) messages) {
  update_stats(stats)
  List.iter(function(message) {
    line = <div class="line">
              <span class="date">{Date.to_string_time_only(message.date)}</span>
              { match (message.source) {
                case {system} : <span class="system"/>
                case {~user} : <span class="user">{user.name}</span>
                }
              }
              <span class="message">{message.text}</span>
           </div>
    #conversation =+ line
  }, messages)
  Dom.scroll_to_bottom(#conversation)
}

exposed function server_broadcast(user, text) {
  message = {source:user, ~text, date:Date.now()}
  /history[?] <- message
  Network.broadcast({~message}, room)
}

client function broadcast(user, _) {
  _ = server_broadcast(user, Dom.get_value(#entry))
  Dom.clear_value(#entry)
}

server function client_observe(msg) {
  match (msg) {
  case {~message} :
    message_update(compute_stats(), [message])
  case {stats} :
    update_stats(compute_stats())
    users = ServerReference.get(users)
    users_html_list = List.fold(function(elt, acc) {
                        <><li>{elt.name}</li>{acc}</>
                      }, users, <></>)
    update_users(List.length(users), users_html_list)
  default : void
  }
}

server function init_client(user, client_channel) {
  Log.notice("Init", "client")
  obs = Network.observe(client_observe, room)
  Network.broadcast({connection:(user, client_channel)}, room)
  Dom.bind_beforeunload_confirmation(function(_) {
    Network.broadcast({disconnection:user}, room)
    Network.unobserve(obs)
    none
  })
  history_list = IntMap.To.val_list(/history)
  len = List.length(history_list)
  history = List.drop(len-NB_LAST_MSGS, history_list)
  message_update(compute_stats(), history)
}

server @async function enter_chat(user_name, client_channel) {
  Log.notice("Init", "{user_name} entered chat")
  user = {
    id: Random.int(max_int),
    name: user_name
  }
  broadcast = broadcast({user: user}, _)
  #main = build_page(
            <iframe src="http://markdotto.github.com/github-buttons/github-btn.html?user={GITHUB_USER}&repo={GITHUB_REPO}&type=fork&count=true&size=large"
                    allowtransparency="true" frameborder="0" scrolling="0" width="146px" height="30px"></iframe>,
    WBootstrap.Layout.fluid(
      <div id=#user_list/>
      <div id=#stats><div id=#users/><div id=#uptime/><div id=#memory/></div>,
      <div id=#conversation onready={function(_){init_client(user, client_channel)}}/>
      <div id=#chatbar>
        <input id=#entry
               onready={function(_){Dom.give_focus(#entry)}}
               onnewline={broadcast}/>
      </div>
    )
  )
}

client function join(_) {
  name = Dom.get_value(#name)
  #welcome = <p>Loading chat...</p>
  client_channel = Session.make_callback(ignore)
  enter_chat(name, client_channel)
}

function start() {
  <div id=#main>{
    build_page(<h1>Wecome to OpaChat</h1>,
      <div id=#welcome>
        <label for="name">Choose your name: </label>
        <input id=#name placeholder="Name"
               onready={function(_){Dom.give_focus(#name)}}
               onnewline={join}/>
        <button class="btn primary"
                onclick={join}>Join</button>
      </div>
    )
  }</div>
}

Server.start(Server.http, [
  {resources: @static_resource_directory("resources")}, // include resources directory
  {register: ["/resources/css/bootstrap.min.css", "/resources/css/style.css"]}, // web application CSS
  {title: "OpaChat - a chat built with Opa", page:start }
  ]
)
