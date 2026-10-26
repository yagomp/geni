import Foundation
import StoreKit

/// Where the child's App Store account is, so money, units and seasons feel local anywhere.
/// The storefront is read once per launch and cached; before that (and offline) the device region is used.
nonisolated enum StoreRegion {
    private static let cacheKey = "geni_storefront_country"

    /// ISO 3166-1 alpha-2, e.g. "NO", "ES", "US".
    static var countryCode: String {
        if let override = ProcessInfo.processInfo.environment["GENI_STORE_REGION"] ?? launchArgument {
            return override.uppercased()
        }
        return UserDefaults.standard.string(forKey: cacheKey)
            ?? Locale.current.region?.identifier
            ?? "US"
    }

    /// ISO 4217 code for the storefront country, e.g. "NOK", "EUR", "USD".
    static var currencyCode: String {
        Locale(identifier: "und_\(countryCode)").currency?.identifier ?? "EUR"
    }

    /// Countries that measure in inches, feet and pounds day to day.
    static var usesImperial: Bool { ["US", "LR", "MM"].contains(countryCode) }

    /// Seasons flip south of the equator (December is summer in Brazil and Australia).
    static var isSouthernHemisphere: Bool { southern.contains(countryCode) }

    /// `-geniStoreRegion BR` for screenshots and QA.
    private static var launchArgument: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-geniStoreRegion"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    /// Called at launch; cheap and silent when there's no App Store account.
    static func refresh() async {
        guard let alpha3 = await Storefront.current?.countryCode, let alpha2 = alpha2(fromAlpha3: alpha3) else { return }
        UserDefaults.standard.set(alpha2, forKey: cacheKey)
    }

    static func alpha2(fromAlpha3 code: String) -> String? {
        alpha3To2[code.uppercased()]
    }

    private static let southern: Set<String> = [
        "AR", "AU", "BO", "BR", "BW", "CL", "FJ", "LS", "MG", "MU", "MZ", "NA", "NZ", "PE", "PY", "SZ", "UY", "ZA", "ZM", "ZW"
    ]

    private static let alpha3To2: [String: String] = [
        "NOR": "NO", "SWE": "SE", "DNK": "DK", "FIN": "FI", "ISL": "IS", "GBR": "GB", "IRL": "IE",
        "DEU": "DE", "AUT": "AT", "CHE": "CH", "LIE": "LI", "LUX": "LU", "BEL": "BE", "NLD": "NL",
        "FRA": "FR", "MCO": "MC", "ESP": "ES", "AND": "AD", "PRT": "PT", "ITA": "IT", "MLT": "MT",
        "GRC": "GR", "CYP": "CY", "POL": "PL", "CZE": "CZ", "SVK": "SK", "HUN": "HU", "SVN": "SI",
        "HRV": "HR", "ROU": "RO", "BGR": "BG", "EST": "EE", "LVA": "LV", "LTU": "LT", "UKR": "UA",
        "TUR": "TR", "ISR": "IL", "ARE": "AE", "SAU": "SA", "QAT": "QA", "EGY": "EG", "MAR": "MA",
        "ZAF": "ZA", "NGA": "NG", "KEN": "KE", "GHA": "GH", "USA": "US", "CAN": "CA", "MEX": "MX",
        "GTM": "GT", "CRI": "CR", "PAN": "PA", "DOM": "DO", "PRI": "PR", "COL": "CO", "VEN": "VE",
        "ECU": "EC", "PER": "PE", "BOL": "BO", "CHL": "CL", "ARG": "AR", "URY": "UY", "PRY": "PY",
        "BRA": "BR", "AUS": "AU", "NZL": "NZ", "JPN": "JP", "KOR": "KR", "CHN": "CN", "HKG": "HK",
        "TWN": "TW", "SGP": "SG", "MYS": "MY", "THA": "TH", "VNM": "VN", "PHL": "PH", "IDN": "ID",
        "IND": "IN", "PAK": "PK", "LKA": "LK", "AGO": "AO", "MOZ": "MZ", "CPV": "CV", "LBR": "LR", "MMR": "MM"
    ]
}
