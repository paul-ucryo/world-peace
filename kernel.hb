#bootstrap, use smtp as a contact surface for ddns. Then use home router as a stable server hosting your own social media data backed by your custom ACS graph.
#federation and distribution mechanics are defined in .policy and enforced by acs cap map. So trust networks can build between friends not sharing data but hosting each others backup store without access permissions. 
#social media becomes .policy rules over self hosted data stores with swapable front ends.
mount volume -> cat happy | birthday  #A new domain is a volume containing happy and birthday, where birthday is executable and happy is the config.
                    -> cat good |morning #An existing session can be unzipped or reset by calling morning, with good as the default load config.

#This system reframes "everything is a file" to "everything is a function" and becomes a coordination map for side effects.
{domain}/
    .acs/   #identity is a session monad (implemented as, each identity is a ca). acs is the identity relational graph, a cryptographic capability map enforcing domain soverienty
    .hb/    #handbook is the log/note/comment/manuals/documentation system
        {session_id}.hb
    .pulse/ #so objects, running drivers. fuse, script runtimes, whatever drives state forward. The connector layer between runtime and .policy file.
            #This makes .pulse the neural network transform. How the system responds to any given input. So calling an event in pulse is a 1:1 relation. Fuzzy search between input state and the .pulse structure produces a compositional autmoation structure. Which is just a neural net transform serialized to the fs ns.
        @{event}.sh    #the async 'tick' system or session scheduler clock. Basically a type system for event handling.
        #so each thing writes events to pulse/event, and @{event}.sh gets called to process against current state. Giving you ability to flush specific events or add them to the buffer and handled on the next ui loop call to _.sh
        #so things may write without flush if they aren't in a hurry. Flush is running _.sh -> the cursor's shell env
        policy.sh  #This may not be necessary, but was intended as the handle for the policy runtime, as in what systemd would point to.
        # file name could be a hint for all the files matching process through that, such that the system just runs the file against the result of greping the file name in the current directory.
        # as in -> ls .pulse/ | grep {event} | xargs sh. i think thats wrong, the idea is the .pulse folder files are named by their scope. so regex matches between event and file name would return the execution context.
        # Incoherent interaction should create a "hello|help" file in the current working directory. and reading from it produces changes to the system as does writing to it. all based on .policy. So you can get smallTalk style instructions of how to use your system.
        # writing to login connects you to a session context or creates one if what you write doesn't exist, strongly connected to .hb entries.
    .vcs/  #composable state vectors, similar in spirit to pijule. basically making cow references first class objects in the domain design/maintainance.
        _/  #The systems internal channel
        public/ #published/public content. Implies stable/recent
    gw/  #Generalized contact store. vCard data, dns, anything contactable should have a route defined here.
        #strongly linked to acs records {name:"",upu:"",pstn:"",..}
      _/  #internal identity router. Mostly defines how local users connect to remote resources
        user1/
        home/
        work/
        proj-x/
      ypages/ #consumer facing business address registry
      fednet/ #contacts for a federated trust network
    audit/  #published QC/QA reports. Test reports, financial audit logs, product QC, ..
    catalog/  #basically the global namespace, the logical deconstruction of any symentic namespace (part dependency/heirarchy, large project decomposition, acs role logic,..)
        bcp47/  #making the language system a catalog object. Lets you create tokenize characters like LLM graphs for effecient searching/prediction, where the system state is the transform geometry and updating it is 'training'.
    inventory/
    budget/ #txn records
        tax/
        .policy #budget monad
    design/
        31d.catalog/  #3+1D -> basically cad data. The spacial definition of a thing.    
          #"." -> join. Meaning you can operate on a directory in one and the action mirrors the other. Maybe its a symlink to a .cad file inside catalog as a first implementation?
        i.catalog/  #imaginary axis, the stuff constructing the thing (usually cam data). 31d tells you what, the i tells you how to produce that from the environment.
                    #I like to think of the imaginary axis of a component as the negative or 'hole' of the component, the set of resources that once resolved would produce the object.
        schema.catalog/  #logical wire graph. mostly svg drawings of logic structure, like wiring tables, project flow diagrams, symulink programs, ..
        src/
            index.html #public home page
            session.html #login session
    media/
        img/  #image and recorded video.
        src/    #Live data (stream channels). ch might be a better name, but src captures the intent of stream source better then ch at this stage of dev.
            home/back_porch.cctv
            laptop1/speaker1
    share/ #where public puts data (forms, config, session specific data).
          #media and share are similar in spirit to read/write io but defined by ownership boundary not direction.
        {session_ca_id}/   #cctv sensor client writes here
    .policy #basically monad definition all contents run against on 'write' or resolve (_.sh).

.policy {
    "import":["nda0","gpl3"],
    "_":"nda0",
    "#_":"thats the private context handle",
    "pub":"gpl3",
    "#pub":"published context. basically signed or asserted by you",
    "": "",
    "#":"the empty string is the default behavior, so in this case the default action is anonymity. To get privacy, post encrypted data anonymously and don't share your acs store, so there is no public gateway to identify the decryption but you maintain the links locally"
}
#data ownership contracts need development, but the idea is that the 'license' or 'copywrite' is a cryptographic capability, not just an honor system with legal backing.
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

