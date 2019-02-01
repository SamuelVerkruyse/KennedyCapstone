//
//  Query.swift
//  App
//
//  Created by Ethan Kusters on 1/30/19.
//

import Vapor

final class Query: Codable {
    var query: String?
    var allExplicit: String?
    var anyExplicit: String?
    var phraseExplicit: String?
    var noneExplicit: String?
    
    var author: String?
    var excludeAuthor = false
    
    var title: String?
    var excludeTitle = false
    
    var location: String?
    var excludeLocation = false
    
    var excludeLetters = false
    var excludeTelegrams = false
    var excludeDocuments = false
    var excludeDrawings = false
    var excludeInvoices = false
    
    static let defaultFirstDate = "1915-01-01"
    static let defaultSecondDate = "1945-12-31"
    
    var firstDate = Query.defaultFirstDate
    var secondDate = Query.defaultSecondDate
    var excludeDates = false
    
    let currentSearchURL: String
    
    private let baseURL = IslandoraService.baseURL + "solr/"
    private let urlSuffix = "?rows=15&omitHeader=true&wt=json&start="
    private let restrictToCollectionQuery = "(RELS_EXT_hasModel_uri_t:bookCModel AND ancestors_ms:\"rekl:morgan-ms010\")"
    
    init(queryParameters: QueryContainer, currentSearchURL: String) {
        let regex = try! NSRegularExpression(pattern: "&?page=\\d*")
        self.currentSearchURL = regex.stringByReplacingMatches(in: currentSearchURL, options: [], range: NSMakeRange(0, currentSearchURL.count), withTemplate: "")
        
        if let queryParam = queryParameters[String.self, at: "query"] { query = queryParam }
        
        if let allExplicitParam = queryParameters[String.self, at: "all_explicit"] { allExplicit = allExplicitParam }
        
        if let anyExplicitParam = queryParameters[String.self, at: "any_explicit"] { anyExplicit = anyExplicitParam }
        
        if let phraseExplicitParam = queryParameters[String.self, at: "phrase_explicit"] { phraseExplicit = phraseExplicitParam }
        
        if let noneExplicitParam = queryParameters[String.self, at: "none_explicit"] { noneExplicit = noneExplicitParam }
        
        if let authorParam = queryParameters[String.self, at: "author"] { author = authorParam }
        
        if let excludeAuthorParam = queryParameters[Bool.self, at: "exclude_author"] { excludeAuthor = excludeAuthorParam }
        
        if let titleParam = queryParameters[String.self, at: "title"] { title = titleParam }
        
        if let excludeTitleParam = queryParameters[Bool.self, at: "exclude_title"] { excludeTitle = excludeTitleParam }
        
        if let locationParam = queryParameters[String.self, at: "location"] { location = locationParam }
        
        if let excludeLocationParam = queryParameters[Bool.self, at: "exclude_location"] { excludeLocation = excludeLocationParam }
        
        if let excludeLettersParam = queryParameters[Bool.self, at: "exclude_letters"] { excludeLetters = excludeLettersParam }
        
        if let excludeTelegramsParam = queryParameters[Bool.self, at: "exclude_telegrams"] { excludeTelegrams = excludeTelegramsParam }
        
        if let excludeDocumentsParam = queryParameters[Bool.self, at: "exclude_documents"] { excludeDocuments = excludeDocumentsParam }
        
        if let excludeDrawingsParam = queryParameters[Bool.self, at: "exclude_drawings"] { excludeDrawings = excludeDrawingsParam }
        
        if let excludeInvoicesParam = queryParameters[Bool.self, at: "exclude_invoices"] { excludeInvoices = excludeInvoicesParam  }
        
        if let firstDateParam = queryParameters[String.self, at: "first_date"] { firstDate = firstDateParam }
        
        if let secondDateParam = queryParameters[String.self, at: "second_date"] { secondDate = secondDateParam }
        
        if let excludeDatesParam = queryParameters[Bool.self, at: "exclude_dates"] { excludeDates = excludeDatesParam }
    }
    
    func getSolrSearch(start: Int) -> String? {
        var solrSearch = baseURL + restrictToCollectionQuery
        
        if var query = query {
            query = query.trimmingCharacters(in: .whitespacesAndNewlines)
            let wildCardQuery = query.replacingOccurrences(of: " ", with: "~ ") + "~"
            let fuzzyQuery = query.replacingOccurrences(of: " ", with: "* ") + "*"
            
            solrSearch.append(" AND (dc.title:\(wildCardQuery) OR dc.description:\(wildCardQuery) OR OCR_BOOK_t:\(wildCardQuery) OR dc.title:\(fuzzyQuery) OR dc.description:\(fuzzyQuery) OR OCR_BOOK_t:\(fuzzyQuery))")
        }
        
        if let allExplicit = allExplicit {
            let terms = allExplicit.split(separator: " ")
            
            for term in terms {
                solrSearch.append(" AND (OCR_BOOK_t:\"\(term)\")")
            }
        }
        
        if let anyExplicit = anyExplicit {
            let terms = anyExplicit.split(separator: " ")
            
            var termsCombined = ""
            
            for term in terms {
                if !termsCombined.isEmpty {
                    termsCombined.append(" OR ")
                }
                
                termsCombined.append("(OCR_BOOK_t:\"\(term)\")")
            }
            
            solrSearch.append("AND (\(termsCombined))")
        }
        
        if let phraseExplicit = phraseExplicit {
            let phrases = phraseExplicit.components(separatedBy: "\" \"")
            
            for phrase in phrases {
                solrSearch.append(" AND (OCR_BOOK_t:\"\(phrase.replacingOccurrences(of: "\"", with: ""))\")")
            }
        }
        
        if let noneExplicit = noneExplicit {
            let terms = noneExplicit.split(separator: " ")
            
            for term in terms {
                solrSearch.append(" AND -(OCR_BOOK_t:\"\(term)\")")
            }
        }
        
        if let author = author {
            if excludeAuthor {
                solrSearch.append(" AND -(mods_name_personal_author_namePart_t:\(author))")
            } else {
                solrSearch.append(" AND (mods_name_personal_author_namePart_t:\(author))")
            }
        }
        
        if let title = title {
            if excludeTitle {
                solrSearch.append(" AND -(mods_titleInfo_title_t:\(title))")
            } else {
                solrSearch.append(" AND (mods_titleInfo_title_t:\(title))")
            }
        }
        
        if let location = location {
            if excludeLocation {
                solrSearch.append(" AND -((mods_subject_hierarchicalGeographic_city_t:\(location)) OR (mods_subject_hierarchicalGeographic_state_s:\(location)))")
            } else {
                solrSearch.append(" AND ((mods_subject_hierarchicalGeographic_city_t:\(location)) OR (mods_subject_hierarchicalGeographic_state_s:\(location)))")
            }
        }
        
        if excludeLetters {
            solrSearch.append(" AND -(mods_genre_t:letter)")
        }
        
        if excludeTelegrams {
            solrSearch.append(" AND -(mods_genre_t:telegram)")
        }
        
        if excludeDocuments {
            solrSearch.append(" AND -(mods_genre_t:document)")
        }
        
        if excludeDrawings {
            solrSearch.append(" AND -(mods_genre_t:drawing)")
        }
        
        if excludeInvoices {
            solrSearch.append(" AND -(mods_genre_t:invoice)")
        }
        
        if firstDate != Query.defaultFirstDate || secondDate != Query.defaultSecondDate {
            if excludeDates {
                solrSearch.append(" AND -(mods_originInfo_dateCreated_dt:[\(firstDate)T00:00:00Z TO \(secondDate)T00:00:00Z])")
            } else {
                solrSearch.append(" AND (mods_originInfo_dateCreated_dt:[\(firstDate)T00:00:00Z TO \(secondDate)T00:00:00Z])")
            }
        }
        
        solrSearch.append(urlSuffix)        
        solrSearch.append(String(start))
        
        return solrSearch.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
}
