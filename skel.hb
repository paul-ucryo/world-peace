{domain}/
    .acs/   #identity is a session monad. acs is the identity relational graph
    .hb/    #handbook is the log/note/comment/manuals/documentation system
        {session_id}.hb
    .vcs/
        public/ #published/public content. Implies stable/recent
    audit/
    catalog/
    inventory/
    budget/ #txn records
        .policy #budget monad
    design/
        cad/
        nc/
        schema/
        src/
            index.html #public home page
            session.html #login session
    media/
        img/
    share/ #where public puts data (forms, config, session specific data).
        {session_id}/
    .policy #basically monad definition all contents run against on 'write'


.policy {
    "": "gnu",
    "#":"the empty string the default behavior, so in this case gnu is the default session context"
}

.acs/gnu {
    "label":"gnu",
    "name":"",
    "dscr":"{GNU GPL full desription}",
    "seal":["fs:{pubkey}","fs:{privkey}","fs:{symkey}"],
    "":"{signature}"
}

