import Foundation
import D2MessageIO
import Graphics
import GIF
import Utils
import Logging

public class PatCommand: Command {
    public let info = CommandInfo(
        category: .fun,
        shortDescription: "Creates a pat animation",
        requiredPermissionLevel: .basic,
        platformAvailability: ["Discord"] // Due to Discord-specific CDN URLs
    )
    public let inputValueType: RichValueType = .image
    public let outputValueType: RichValueType = .gif

    private let frameCount: Int
    private let delayTime: Int
    private let patOffset: Vec2<Double>
    private let patScale: Double
    private let patPower: Int

    private let inventoryManager: InventoryManager

    public init(
        frameCount: Int = 25,
        delayTime: Int = 3,
        patOffset: Vec2<Double> = .init(x: -10),
        patScale: Double = -10,
        patPower: Int = 2,
        inventoryManager: InventoryManager
    ) {
        self.frameCount = frameCount
        self.delayTime = delayTime
        self.patOffset = patOffset
        self.patScale = patScale
        self.patPower = patPower
        self.inventoryManager = inventoryManager
    }

    public func invoke(with input: RichValue, output: CommandOutput, context: CommandContext) {
        guard let user = input.asMentions?.first else {
            output.append(errorText: "Please mention someone!")
            return
        }
        guard let author = context.author else {
            output.append(errorText: "No author")
            return
        }

        context.channel?.triggerTyping()

        // TODO: Add MessageClient API for fetching avatars to reduce
        //       code duplication among this command and e.g. AvatarCommand
        Promise.catching { try HTTPRequest(
            scheme: "https",
            host: "cdn.discordapp.com",
            path: "/avatars/\(user.id)/\(user.avatar).png",
            query: ["size": "128"]
        ) }
            .then { $0.runAsync() }
            .listen {
                do {
                    let data = try $0.get()
                    guard !data.isEmpty else {
                        output.append(errorText: "No avatar available")
                        return
                    }

                    let patHand = try Image(fromPngFile: "Resources/fun/patHand.png")
                    var avatarImage = try Image(fromPng: data)
                    let width = avatarImage.width
                    let height = avatarImage.height
                    let radiusSquared = (width * height) / 4
                    var gif = AnimatedGIF(quantizingImage: avatarImage)

                    // Cut out round avatar
                    for y in 0..<height {
                        for x in 0..<width {
                            let cx = x - (width / 2)
                            let cy = y - (height / 2)
                            if (cx * cx) + (cy * cy) > radiusSquared {
                                avatarImage[y, x] = Colors.transparent
                            }
                        }
                    }

                    // Render the animation
                    for i in 0..<self.frameCount {
                        let frame = try Image(width: width, height: height)
                        let percent = Double(i) / Double(self.frameCount)
                        var graphics = CairoGraphics(fromImage: frame)

                        graphics.draw(avatarImage)
                        graphics.draw(patHand, at: self.patOffset + Vec2(y: self.patScale * (1 - abs(pow(2 * percent - 1, Double(self.patPower))))))

                        gif.append(frame: .init(image: frame, delayTime: self.delayTime))
                    }

                    output.append(.gif(gif))

                    // Place the pat in the recipient's inventory
                    self.inventoryManager[user].append(item: .init(id: "pat-\(author.username)", name: "Pat by \(author.username)"), to: "Pats")
                } catch {
                    output.append(errorText: "The avatar could not be fetched \(error)")
                }
            }
    }
}