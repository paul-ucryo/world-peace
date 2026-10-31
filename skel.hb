
init -> mount volume -> cat happy | birthday
{domain}/
    .acs/   #identity is a session monad. acs is the identity relational graph
    .hb/    #handbook is the log/note/comment/manuals/documentation system
        {session_id}.hb
    .pulse/ #so objects, running drivers. fuse, script runtimes, whatever drives state forward. The connector layer between runtime and .policy file.
        @{event}.sh    #the async 'tick' system or session scheduler clock.
        #so each thing writes events to pulse/event, and @{event}.sh gets called to process against current state.
        #so things may write without flush if they aren't in a hurry. Flush is running _.sh -> the cursor's shell env
        policy.sh
        # file name should be a hint for all the files matching process through that, such that the system just runs the file against the result of greping the file name in the current directory.
        # as in -> ls .pulse/ | grep {event} | xargs sh
        # which should create a "hello|help" file in the current working directory. and reading from it produces changes to the system as does writing to it. all based on .policy. So you can get smallTalk style instructions of how to use your system.
        # writing to login connects you to a session context or creates one if what you write doesn't exist, strongly connected to .hb entries.
    .vcs/
        _/  #The systems internal channel
        public/ #published/public content. Implies stable/recent
    audit/
    catalog/
    inventory/
    budget/ #txn records
        .policy #budget monad
    design/
        cad.catalog/    #"." -> join. Meaning you can operate on a directory in one and the action mirrors the other. Maybe its a symlink to a .cad file inside catalog as a first implementation?
        nc.catalog/
        schema.catalog/
        src/
            index.html #public home page
            session.html #login session
    media/
        img/
        src/    #stream channels
            home.cctv
            speaker1
    share/ #where public puts data (forms, config, session specific data).
        {session_id}/   #cctv sensor client writes here
    .policy #basically monad definition all contents run against on 'write'

.policy {
    "import":["nda0","gpl3"],
    "_":"nda0",
    "#_":"thats the private context handle",
    "pub":"gpl3",
    "#pub":"published context. basically signed or asserted by you",
    "": "",
    "#":"the empty string is the default behavior, so in this case the default action is anonymity"
}

.acs/nda0 {
    "label":"nda0",
    "name":"NDA-0",
    "dscr":"Cryptographic enforcement of sealed content",
    "${label}":"{sha256(fs.nda0)}",
    "seal":["fs:{pubkey}","fs:{privkey}","fs:{symkey}"],
    "":"${signature}"
}
.acs/gpl3 {
    "label":"gpl3",
    "name":"GPL-3.0",
    "dscr":"Cryptographic enforcement of copyleft as defined by GPL-3.0",
    "${label}":"{sha256(fs.gpl3.0)}",
    "seal":["fs:{pubkey}","fs:{privkey}","fs:{symkey}"],
    "":"${signature}"
}

