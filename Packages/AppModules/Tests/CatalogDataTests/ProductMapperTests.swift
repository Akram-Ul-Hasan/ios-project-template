import CatalogData
import Core
import Foundation
import SharedDomain
import Testing

@Suite("Product mappers")
struct ProductMapperTests {
    private func product(_ fields: String) throws -> ProductResponse {
        try JSONDecoder.app.decode(ProductResponse.self, from: Data("{\(fields)}".utf8))
    }

    private let base = #""id":"p1","name":"Rice","price":450"#

    @Test("A valid product maps exactly; absent tags become an empty list")
    func valid() throws {
        let entity = try product(
            base + #","discount_price":399,"image_url":"https://cdn.test/p1.jpg","status":"active""#
        ).toEntity()
        #expect(
            entity
                == ProductEntity(
                    id: "p1", name: "Rice", price: 450, discountPrice: 399,
                    imageURL: URL(string: "https://cdn.test/p1.jpg"),
                    tags: [], status: .active))
    }

    @Test("A missing required field fails decoding")
    func missingRequired() {
        #expect(throws: DecodingError.self) { try product(#""id":"p1","name":"Rice","status":"active""#) }
    }

    @Test("An unknown status is kept, not a failure")
    func unknownStatus() throws {
        #expect(try product(base + #","status":"pre_order""#).toEntity().status == .unknown("pre_order"))
    }

    @Test(
        "Each broken invariant throws its MappingError",
        arguments: [
            (#""id":"","name":"Rice","price":1,"status":"active""#, MappingError.invalidValue("product.id", "empty")),
            (#""id":"p1","name":" ","price":1,"status":"active""#, .invalidValue("product.name", "empty")),
            (#""id":"p1","name":"Rice","price":-1,"status":"active""#, .invalidValue("product.price", "negative")),
            (
                #""id":"p1","name":"Rice","price":10,"discount_price":-1,"status":"active""#,
                .invalidValue("product.discountPrice", "negative")
            ),
            (
                #""id":"p1","name":"Rice","price":10,"discount_price":11,"status":"active""#,
                .invalidValue("product.discountPrice", "greater than price")
            ),
        ])
    func guards(fields: String, expected: MappingError) throws {
        let response = try product(fields)
        #expect(throws: expected) { try response.toEntity() }
    }

    @Test("Details: negative stock is rejected; unusable gallery URLs are skipped")
    func details() throws {
        func details(_ extra: String) throws -> ProductDetailsResponse {
            try JSONDecoder.app.decode(
                ProductDetailsResponse.self,
                from: Data(#"{"id":"p1","name":"Rice","price":10,"status":"active","description":"d",\#(extra)}"#.utf8))
        }
        let negative = try details(#""stock":-1"#)
        #expect(throws: MappingError.invalidValue("product.stock", "negative")) { try negative.toEntity() }
        let gallery = try details(#""stock":3,"images":["https://cdn.test/a.jpg",""]"#).toEntity()
        #expect(gallery.imageURLs == [URL(string: "https://cdn.test/a.jpg")])
    }

    @Test("A page fails as a whole if one item is broken (no silent partial lists)")
    func pageFailsAsWhole() throws {
        let json =
            #"{"items":[{"id":"p1","name":"A","price":1,"status":"active"},{"id":"","name":"B","price":1,"status":"active"}],"page":1,"has_next":false}"#
        let page = try JSONDecoder.app.decode(PaginatedResponse<ProductResponse>.self, from: Data(json.utf8))
        #expect(throws: MappingError.invalidValue("product.id", "empty")) { try page.toEntity() }
    }
}
