import Foundation
import Logging
import SQLite
import D2MessageIO
import D2Utils

fileprivate let guilds = Table("guilds")
fileprivate let guildId = Expression<Int64>("guild_id")
fileprivate let guildName = Expression<String>("guild_name")

fileprivate let channels = Table("channels")

// TODO: Users table?

fileprivate let messages = Table("messages")
fileprivate let messageId = Expression<Int64>("message_id")
fileprivate let authorId = Expression<Int64>("author_id")
fileprivate let channelId = Expression<Int64>("channel_id")
fileprivate let content = Expression<String>("content")
fileprivate let timestamp = Expression<Date>("timestamp")
fileprivate let hasAttachments = Expression<Bool>("has_attachments")
fileprivate let hasEmbed = Expression<Bool>("has_embed")

fileprivate let markovTransitions = Table("markov_transitions")
fileprivate let wordA = Expression<String>("word_a")
fileprivate let wordB = Expression<String>("word_b")
fileprivate let followingWord = Expression<String>("following_word")
fileprivate let occurrences = Expression<Int64>("occurrences")

fileprivate let log = Logger(label: "D2Commands.MessageDatabase")
    
public class MessageDatabase {
    private let db: Connection
    
    public init() throws {
        db = try Connection("local/messages.sqlite3")
    }
    
    public func setupTables() throws {
        try db.run(guilds.create(ifNotExists: true) {
            $0.column(guildId, primaryKey: true)
            $0.column(guildName)
        })
        try db.run(channels.create(ifNotExists: true) {
            $0.column(channelId, primaryKey: true)
            $0.column(guildId, references: guilds, guildId)
        })
        try db.run(messages.create(ifNotExists: true) {
            $0.column(messageId, primaryKey: true)
            $0.column(authorId) // TODO: references user table?
            $0.column(channelId, references: channels, channelId)
            $0.column(content)
            $0.column(timestamp)
            $0.column(hasAttachments)
            $0.column(hasEmbed)
        })
        try db.run(markovTransitions.create(ifNotExists: true) {
            $0.column(wordA)
            $0.column(wordB)
            $0.column(followingWord)
            $0.column(occurrences)
            $0.primaryKey(wordA, wordB, followingWord)
        })
    }
    
    public func prepare(sql: String) throws -> Statement {
        try db.prepare(sql)
    }

    public func queryMissingMessages(with client: MessageClient, from guildId: GuildID) throws {
        // TODO
    }
    
    public func insertMessage(message: Message) throws {
        guard let messageMessageId = message.id else { throw MessageDatabaseError.missingID("Missing message ID") }
        guard let messageChannelId = message.channelId else { throw MessageDatabaseError.missingID("Missing channel ID in message") }
        guard let messageAuthorId = message.author?.id else { throw MessageDatabaseError.missingID("Missing author ID in message") }
        guard let messageTimestamp = message.timestamp else { throw MessageDatabaseError.missingTimestamp }
        try db.run(messages.insert(
            messageId <- try convert(id: messageMessageId),
            channelId <- try convert(id: messageChannelId),
            authorId <- try convert(id: messageAuthorId),
            content <- message.content,
            timestamp <- messageTimestamp,
            hasAttachments <- (message.attachments.count > 0),
            hasEmbed <- (message.embeds.count > 0)
        ))
    }
    
    private func convert(id: ID) throws -> Int64 {
        guard let idValue = Int64(id.value) else {
            throw MessageDatabaseError.invalidID("ID \(id.value) cannot be represented as a 64-bit unsigned int!")
        }
        return idValue
    }
    
    @discardableResult
    public func generateMarkovTransitions(for message: Message) throws -> Int {
        try generateMarkovTransitions(text: message.content)
    }
    
    @discardableResult
    public func generateMarkovTransitions(text: String? = nil) throws -> Int {
        var count = 0

        if let text = text {
            let words = text.split(separator: " ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            let order = 2
            
            if words.count > order {
                try db.transaction {
                    for i in 0..<(words.count - order) {
                        try db.run(markovTransitions.insert(
                            or: .ignore,
                            wordA <- words[i],
                            wordB <- words[i + 1],
                            followingWord <- words[i + order],
                            occurrences <- 0
                        ))
                        try db.run(markovTransitions
                            .filter(wordA == words[i] && wordB == words[i + 1])
                            .update(occurrences++))
                        count += 1
                    }
                }
            }
        } else {
            let msgCount = try db.scalar(messages.count)
            let chunkSize = msgCount / 10

            for (i, msg) in try db.prepare(messages.select(messageId, content)).enumerated() {
                count += try generateMarkovTransitions(text: msg[content])
                
                if i % chunkSize == 0 {
                    let progress = Double(i) / Double(msgCount)
                    log.info("Markov transitions \(String(format: "%.2f", progress * 10))% completed...")
                }
            }
        }
        
        return count
    }
}
