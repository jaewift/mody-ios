//
//  AppAssembly+FeedChat.swift
//  Mody
//
//  Created by Jaewift on 11/11/26.
//

import Swinject
import CoreAuthInterface
import CoreNetworkInterface
import FeedInterface
import Feed

extension AppAssembly {
    func assembleFeedChatReactor(in container: Container) {
        container.register(FeedChatRepositoryProtocol.self) { resolver in
            let network: CoreNetworkProtocol = resolver.resolve()

            return FeedChatRepository(network: network)
        }

        container.register(FeedChatUseCase.self) { resolver in
            let chatRepository: FeedChatRepositoryProtocol = resolver.resolve()

            return FeedChatUseCase(chatRepository: chatRepository)
        }

        container.register(((FeedChatRouter, Int, Int, FeedChatOutputHandler) -> FeedChatReactor).self) { resolver in
            return { router, groupId, recordId, outputHandler in
                let chatUseCase: FeedChatUseCase = resolver.resolve()
                let feedUseCase: FeedUseCase = resolver.resolve()
                let authUseCase: AuthUseCaseProtocol = resolver.resolve()

                return FeedChatReactor(
                    router: router,
                    groupId: groupId,
                    recordId: recordId,
                    chatUseCase: chatUseCase,
                    feedUseCase: feedUseCase,
                    authUseCase: authUseCase,
                    output: { [weak outputHandler] output in
                        outputHandler?.handle(output: output)
                    }
                )
            }
        }
    }
}
