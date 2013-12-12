# Real-time single-room chat with file sharing, built in Opa.

## Requirements

[Opa](https://opalang.org/get.xmlt) build > 4051

## Build and run

`make`
`./opa_chat.js`

or

`make run`

Open [http://localhost:8080](http://localhost:8080)

## Roadmap

- Update running time in real-time
- Scan attachments for vulnerabilites (AV proxy?)
- Multiple chat rooms
- Multiple servers, possibly P2P?
- Ban users who publish messages contained banned keywords
- Ban users who publish too many messages in a row
- Admin users who have banning rights
- File size limit: Detect both client side (to prevent legitimate users to upload the file for nothing) and server side (to prevent forged clients)