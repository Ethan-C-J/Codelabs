/**
 * @license
 * Copyright 2018 Google LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * =============================================================================
 */

 const express = require("express");
 const http = require("http");
 const app = express();
 const server = http.createServer(app);

 var io = require("socket.io")(server);
 
 // Make all the files in 'www' available.
 app.use(express.static("www"));
 
 
 app.get("/", (request, response) => {
   response.sendFile(__dirname + "/www/index.html");
 });

 io.on('connect', socket => {
   console.log("Client Connected");

   socket.on('comment', data => {
    socket.broadcast.emit('remoteComment', data);
   });
 });
 
 // Listen for requests.
 const listener = app.listen(process.env.PORT, () => {
   console.log("Your app is listening on port " + listener.address().port);
 });
 