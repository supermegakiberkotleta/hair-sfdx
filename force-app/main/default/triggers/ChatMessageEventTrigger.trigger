trigger ChatMessageEventTrigger on Chat_Message__e (after insert) {
    ChatMessageEventHandler.handleEvents(Trigger.New);
}