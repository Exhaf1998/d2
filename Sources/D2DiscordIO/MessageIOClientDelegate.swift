import SwiftDiscord
import Logging
import D2MessageIO

fileprivate let log = Logger(label: "MessageIOClientDelegate")

public class MessageIOClientDelegate: DiscordClientDelegate {
    private let inner: MessageDelegate
    
    public init(inner: MessageDelegate) {
        log.info("Creating delegate")
        self.inner = inner
    }

    public func client(_ client: DiscordClient, didConnect connected: Bool) {
        log.debug("Connected")
        inner.on(connect: connected, client: DiscordMessageClient(client: client))
    }
    
    public func client(_ client: DiscordClient, didReceivePresenceUpdate presence: DiscordPresence) {
        log.debug("Got presence update")
        inner.on(receivePresenceUpdate: presence.usingMessageIO, client: DiscordMessageClient(client: client))
    }
    
    public func client(_ client: DiscordClient, didCreateMessage message: DiscordMessage) {
        log.debug("Got message")
        inner.on(createMessage: message.usingMessageIO, client: DiscordMessageClient(client: client))
    }
}