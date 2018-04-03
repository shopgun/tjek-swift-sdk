//
//  ┌────┬─┐         ┌─────┐
//  │  ──┤ └─┬───┬───┤  ┌──┼─┬─┬───┐
//  ├──  │ ╷ │ · │ · │  ╵  │ ╵ │ ╷ │
//  └────┴─┴─┴───┤ ┌─┴─────┴───┴─┴─┘
//               └─┘
//
//  Copyright (c) 2018 ShopGun. All rights reserved.

import UIKit

extension CoreAPI.Requests {
    
    /// Fetch the details about the specified publication
    public static func getPagedPublication(withId pubId: CoreAPI.PagedPublication.Identifier) -> CoreAPI.Request<CoreAPI.PagedPublication> {
        return .init(path: "/v2/catalogs/\(pubId.rawValue)", method: .GET)
    }
    
    /// Fetch all the pages for the specified publication
    public static func getPagedPublicationPages(withId pubId: CoreAPI.PagedPublication.Identifier, aspectRatio: Double? = nil) -> CoreAPI.Request<[CoreAPI.PagedPublication.Page]> {
        return .init(path: "/v2/catalogs/\(pubId.rawValue)/pages", method: .GET, resultMapper: {
            return $0.mapValue {
                // map the raw array of imageURLSets into objects containing page indexes
                let pageURLs = try JSONDecoder().decode([ImageURLSet.CoreAPIImageURLs].self, from: $0)
                return pageURLs.enumerated().map {
                    let images = ImageURLSet(fromCoreAPI: $0.element, aspectRatio: aspectRatio)
                    let pageIndex = $0.offset
                    return .init(index: pageIndex, title: "\(pageIndex+1)", aspectRatio: aspectRatio ?? 1.0, images: images)
                }
            }
        })
    }

    /// Fetch all hotspots for the specified publication
    /// The `aspectRatio` (w/h) of the publication is needed in order to position the hotspots correctly
    public static func getPagedPublicationHotspots(withId pubId: CoreAPI.PagedPublication.Identifier, aspectRatio: Double) -> CoreAPI.Request<[CoreAPI.PagedPublication.Hotspot]> {
        return .init(path: "/v2/catalogs/\(pubId.rawValue)/hotspots", method: .GET, resultMapper: {
            return $0.mapValue {
                return try JSONDecoder().decode([CoreAPI.PagedPublication.Hotspot].self, from: $0).map {
                    /// We do this to convert out of the awful old V2 coord system (which was x: 0->1, y: 0->(h/w))
                    return $0.withScaledBounds(scale: CGPoint(x: 1, y: aspectRatio))
                }
            }
        })
    }
    
    /// Given a publication's Id, this will return
    public static func getSuggestedPublications(relatedTo pubId: CoreAPI.PagedPublication.Identifier, pagination: PaginatedQuery = PaginatedQuery(count: 24)) -> CoreAPI.Request<[CoreAPI.PagedPublication]> {
        
        var params = ["catalog_id": pubId.rawValue]
        params.merge(pagination.requestParams) { (_, new) in new }

        return .init(path: "/v2/catalogs/suggest",
                     method: .GET,
                     requiresAuth: true,
                     parameters: params)
    }
}

// MARK: - Publication Lists

extension CoreAPI.Requests {
    
    public enum PublicationSortOrder {
        case nameAtoZ
        case popularity
        case newestPublished
        case nearest
        case oldestExpiry
        
        fileprivate var sortKeys: [String] {
            switch self {
            case .nameAtoZ:
                return ["name"]
            case .popularity:
                return ["-popularity", "distance"]
            case .newestPublished:
                return ["-publication_date", "distance"]
            case .nearest:
                return ["distance"]
            case .oldestExpiry:
                return ["expiration_date", "distance"]
            }
        }
    }
    
    public static func getPublications(near locationQuery: LocationQuery, sortedBy: PublicationSortOrder, pagination: PaginatedQuery = PaginatedQuery(count: 24)) -> CoreAPI.Request<[CoreAPI.PagedPublication]> {
        
        var params = ["order_by": sortedBy.sortKeys.joined(separator: ",")]
        params.merge(locationQuery.requestParams) { (_, new) in new }
        params.merge(pagination.requestParams) { (_, new) in new }
        
        return .init(path: "/v2/catalogs",
                     method: .GET,
                     requiresAuth: true,
                     parameters: params)
    }
    
    public static func getPublications(matchingSearch searchString: String, near locationQuery: LocationQuery? = nil, pagination: PaginatedQuery = PaginatedQuery(count: 24)) -> CoreAPI.Request<[CoreAPI.PagedPublication]> {
        
        var params = ["query": searchString]
        if let locationQParams = locationQuery?.requestParams {
            params.merge(locationQParams) { (_, new) in new }
        }
        params.merge(pagination.requestParams) { (_, new) in new }

        return .init(path: "/v2/catalogs/search",
                     method: .GET,
                     requiresAuth: true,
                     parameters: params)
    }
    
    public static func getPublications(forStores storeIds: [CoreAPI.Store.Identifier], pagination: PaginatedQuery = PaginatedQuery(count: 24)) ->
        CoreAPI.Request<[CoreAPI.PagedPublication]> {
            var params = ["store_ids": storeIds.map({ $0.rawValue }).joined(separator: ",")]
            params.merge(pagination.requestParams) { (_, new) in new }
            
            return .init(path: "/v2/catalogs",
                         method: .GET,
                         requiresAuth: true,
                         parameters: params)
    }
    
    public static func getFavoritedPublications(near locationQuery: LocationQuery? = nil, sortedBy: PublicationSortOrder, pagination: PaginatedQuery = PaginatedQuery(count: 24)) -> CoreAPI.Request<[CoreAPI.PagedPublication]> {
        
        var params = ["order_by": sortedBy.sortKeys.joined(separator: ",")]
        params.merge(pagination.requestParams) { (_, new) in new }
        if let locationQParams = locationQuery?.requestParams {
            params.merge(locationQParams) { (_, new) in new }
        }
        
        return .init(path: "/v2/catalogs/favorites",
                     method: .GET,
                     requiresAuth: true,
                     parameters: params)
    }
}