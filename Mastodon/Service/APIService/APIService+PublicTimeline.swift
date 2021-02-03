//
//  APIService+PublicTimeline.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/28.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import DateToolsSwift
import MastodonSDK

extension APIService {
    
    static let publicTimelineRequestWindowInSec: TimeInterval = 15 * 60
    
    func publicTimeline(
        domain: String,
        sinceID: Mastodon.Entity.Status.ID? = nil,
        maxID: Mastodon.Entity.Status.ID? = nil,
        limit: Int = 100
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Toot]>, Error> {
        let query = Mastodon.API.Timeline.PublicTimelineQuery(
            local: nil,
            remote: nil,
            onlyMedia: nil,
            maxID: maxID,
            sinceID: sinceID,
            minID: nil,     // prefer sinceID
            limit: limit
        )

        return Mastodon.API.Timeline.public(
            session: session,
            domain: domain,
            query: query
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Toot]>, Error> in
            return APIService.Persist.persistTimeline(
                domain: domain,
                managedObjectContext: self.backgroundManagedObjectContext,
                response: response,
                persistType: Persist.PersistTimelineType.publicTimeline
            )
            .setFailureType(to: Error.self)
            .tryMap { result -> Mastodon.Response.Content<[Mastodon.Entity.Toot]> in
                switch result {
                case .success:
                    return response
                case .failure(let error):
                    throw error
                }
            }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
}
