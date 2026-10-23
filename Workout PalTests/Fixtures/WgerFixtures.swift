import Foundation

enum WgerFixtures {
    static let page = Data("""
    {
      "count": 2,
      "next": null,
      "results": [
        {
          "id": 73,
          "uuid": "0ec76f5d-1b2a-4a76-9b0b-6f4f1c1f6a73",
          "category": { "id": 10, "name": "Abs" },
          "muscles": [{ "id": 6, "name": "Rectus abdominis", "name_en": "Abs" }],
          "muscles_secondary": [{ "id": 14, "name": "Obliquus externus abdominis", "name_en": "" }],
          "equipment": [{ "id": 7, "name": "none (bodyweight exercise)" }],
          "license": {
            "short_name": "CC-BY-SA 4",
            "full_name": "Creative Commons Attribution Share Alike 4",
            "url": "https://creativecommons.org/licenses/by-sa/4.0/deed.en"
          },
          "license_author": "wger.de",
          "images": [
            { "image": "https://wger.de/media/exercise-images/73/side.png", "is_main": false },
            { "image": "https://wger.de/media/exercise-images/73/main.png", "is_main": true }
          ],
          "translations": [
            { "name": "Bauchpresse", "description": "<p>Auf den R&uuml;cken legen.</p>", "language": 1 },
            { "name": "  Crunches ", "description": "<p>Lie on your back &amp; curl up.</p>", "language": 2 }
          ]
        },
        {
          "id": 74,
          "uuid": null,
          "category": null,
          "muscles": [],
          "muscles_secondary": [],
          "equipment": [],
          "license": null,
          "license_author": null,
          "images": [],
          "translations": [{ "name": "Nur auf Deutsch", "description": "", "language": 1 }]
        }
      ]
    }
    """.utf8)
}
