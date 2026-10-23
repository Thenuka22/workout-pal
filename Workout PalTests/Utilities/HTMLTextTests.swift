import Testing
@testable import Workout_Pal

struct HTMLTextTests {
    @Test func turnsParagraphsAndListsIntoLines() {
        let html = "<p>Stand tall &amp; brace.</p><ul><li>Lower slowly</li><li>Drive up</li></ul>"
        #expect(HTMLText.plainText(from: html) == "Stand tall & brace.\n- Lower slowly\n- Drive up")
    }

    @Test func collapsesWhitespaceAndDropsEmptyLines() {
        let html = "<p>  Keep   your\tback straight </p><br><br><p></p>"
        #expect(HTMLText.plainText(from: html) == "Keep your back straight")
    }

    @Test func plainTextIsUnchanged() {
        #expect(HTMLText.plainText(from: "Just text") == "Just text")
    }
}
