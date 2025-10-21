import Foundation

@MainActor
class SubjectContextMapper {
    static let shared = SubjectContextMapper()
    
    private let environmentMappings: [String: ClassroomEnvironmentConfig] = [
        // HISTORY
        "history_maya": ClassroomEnvironmentConfig(
            setting: "maya_ceremonial_center",
            location: "Tikal, Guatemala",
            timeperiod: "1200 CE",
            avatarRole: "maya_elder_historian",
            weatherSystem: "tropical_humid",
            architectureStyle: "maya_pyramids",
            culturalElements: ["calendar_stone", "hieroglyphic_codex", "jade_artifacts", "pyramid_temple"]
        ),
        
        "history_egypt": ClassroomEnvironmentConfig(
            setting: "egyptian_temple",
            location: "Giza Plateau, Egypt",
            timeperiod: "2500 BCE",
            avatarRole: "egyptian_high_priest",
            weatherSystem: "arid_desert",
            architectureStyle: "egyptian_monumental",
            culturalElements: ["pyramid", "hieroglyphics", "scarab_seals", "sarcophagus"]
        ),
        
        "history_rome": ClassroomEnvironmentConfig(
            setting: "roman_forum",
            location: "Rome, Italy",
            timeperiod: "27 BCE",
            avatarRole: "roman_senator",
            weatherSystem: "mediterranean",
            architectureStyle: "roman_classical",
            culturalElements: ["columns", "aqueducts", "togas", "marble_sculptures"]
        ),
        
        "history_greece": ClassroomEnvironmentConfig(
            setting: "ancient_greek_agora",
            location: "Athens, Greece",
            timeperiod: "400 BCE",
            avatarRole: "greek_philosopher",
            weatherSystem: "mediterranean",
            architectureStyle: "greek_classical",
            culturalElements: ["scrolls", "marble_columns", "forum", "olive_trees"]
        ),
        
        "history_viking": ClassroomEnvironmentConfig(
            setting: "viking_longhouse",
            location: "Scandinavia",
            timeperiod: "850 CE",
            avatarRole: "viking_historian",
            weatherSystem: "cold_northern",
            architectureStyle: "viking_maritime",
            culturalElements: ["longship", "runes", "shield", "trading_routes"]
        ),
        
        "history_china_imperial": ClassroomEnvironmentConfig(
            setting: "imperial_chinese_palace",
            location: "Forbidden City, Beijing",
            timeperiod: "1800 CE",
            avatarRole: "imperial_scholar",
            weatherSystem: "moderate",
            architectureStyle: "imperial_chinese",
            culturalElements: ["calligraphy", "silk_scrolls", "tea_ceremony", "dragon_motifs"]
        ),
        
        // SCIENCE - CHEMISTRY
        "science_chemistry": ClassroomEnvironmentConfig(
            setting: "modern_chemistry_lab",
            location: "State-of-the-art Laboratory",
            timeperiod: "2025",
            avatarRole: "chemistry_professor",
            weatherSystem: "controlled_climate",
            architectureStyle: "laboratory_modern",
            culturalElements: ["beakers", "periodic_table", "molecular_models", "spectrometer"]
        ),
        
        "science_chemistry_alchemist": ClassroomEnvironmentConfig(
            setting: "medieval_alchemist_workshop",
            location: "Medieval Europe",
            timeperiod: "1400 CE",
            avatarRole: "alchemist_scholar",
            weatherSystem: "temperate",
            architectureStyle: "medieval_laboratory",
            culturalElements: ["alembic", "furnace", "grimoire", "transmutation_apparatus"]
        ),
        
        // SCIENCE - SPACE
        "science_mars": ClassroomEnvironmentConfig(
            setting: "mars_habitation_base",
            location: "Jezero Crater, Mars",
            timeperiod: "2045",
            avatarRole: "mars_geologist",
            weatherSystem: "martian_dust_storm",
            architectureStyle: "futuristic_habitat",
            culturalElements: ["rover", "habitat_dome", "geology_tools", "solar_panels"]
        ),
        
        "science_astronomy": ClassroomEnvironmentConfig(
            setting: "space_observatory",
            location: "Earth Orbit",
            timeperiod: "2030",
            avatarRole: "astrophysicist",
            weatherSystem: "cosmic_void",
            architectureStyle: "space_station",
            culturalElements: ["telescope", "star_charts", "satellites", "cosmic_map"]
        ),
        
        "science_astronomy_ancient": ClassroomEnvironmentConfig(
            setting: "ancient_observatory",
            location: "Stonehenge, England",
            timeperiod: "2000 BCE",
            avatarRole: "druid_astronomer",
            weatherSystem: "temperate",
            architectureStyle: "neolithic_stone",
            culturalElements: ["standing_stones", "celestial_marker", "zodiac_chart"]
        ),
        
        // SCIENCE - BIOLOGY
        "science_biology_rainforest": ClassroomEnvironmentConfig(
            setting: "amazon_rainforest",
            location: "Amazon Rainforest, Brazil",
            timeperiod: "2025",
            avatarRole: "rainforest_biologist",
            weatherSystem: "tropical_humid",
            architectureStyle: "organic_natural",
            culturalElements: ["exotic_plants", "wildlife", "ecosystem_models", "canopy_layer"]
        ),
        
        "science_marine_biology": ClassroomEnvironmentConfig(
            setting: "underwater_lab",
            location: "Deep Ocean, Atlantic",
            timeperiod: "2025",
            avatarRole: "marine_biologist",
            weatherSystem: "underwater_currents",
            architectureStyle: "submersible_lab",
            culturalElements: ["submarines", "deep_sea_creatures", "pressure_chamber", "coral_reef"]
        ),
        
        "science_microbiology": ClassroomEnvironmentConfig(
            setting: "microscopic_realm",
            location: "Cellular Level",
            timeperiod: "present",
            avatarRole: "cellular_biologist",
            weatherSystem: "controlled",
            architectureStyle: "microscopic_scale",
            culturalElements: ["cell_nucleus", "mitochondria", "DNA_helix", "proteins"]
        ),
        
        // BUSINESS
        "business_silk_road": ClassroomEnvironmentConfig(
            setting: "silk_road_trading_post",
            location: "Samarkand, Uzbekistan",
            timeperiod: "1200 CE",
            avatarRole: "silk_road_merchant",
            weatherSystem: "desert_oasis",
            architectureStyle: "silk_road_bazaar",
            culturalElements: ["caravans", "spices", "trade_routes", "merchant_stalls"]
        ),
        
        "business_modern_stock_market": ClassroomEnvironmentConfig(
            setting: "modern_stock_exchange",
            location: "Wall Street, New York",
            timeperiod: "2025",
            avatarRole: "investment_banker",
            weatherSystem: "urban_climate",
            architectureStyle: "skyscraper_modern",
            culturalElements: ["trading_floor", "ticker_display", "financial_charts"]
        ),
        
        // LANGUAGES
        "language_ancient_greek": ClassroomEnvironmentConfig(
            setting: "ancient_greek_agora",
            location: "Athens, Greece",
            timeperiod: "400 BCE",
            avatarRole: "greek_philosopher",
            weatherSystem: "mediterranean",
            architectureStyle: "greek_classical",
            culturalElements: ["scrolls", "marble_columns", "symposium", "debate_forum"]
        ),
        
        "language_mandarin": ClassroomEnvironmentConfig(
            setting: "imperial_chinese_palace",
            location: "Forbidden City, Beijing",
            timeperiod: "1800 CE",
            avatarRole: "imperial_scholar",
            weatherSystem: "moderate",
            architectureStyle: "imperial_chinese",
            culturalElements: ["calligraphy", "silk_scrolls", "tea_ceremony", "poetry"]
        ),
        
        "language_spanish_colonial": ClassroomEnvironmentConfig(
            setting: "colonial_spanish_city",
            location: "Mexico City",
            timeperiod: "1700 CE",
            avatarRole: "colonial_scholar",
            weatherSystem: "high_altitude",
            architectureStyle: "spanish_colonial",
            culturalElements: ["cathedral", "plaza_mayor", "hacienda", "colonial_art"]
        ),
        
        // ARTS & CULTURE
        "arts_renaissance": ClassroomEnvironmentConfig(
            setting: "renaissance_studio",
            location: "Florence, Italy",
            timeperiod: "1500 CE",
            avatarRole: "renaissance_artist",
            weatherSystem: "temperate",
            architectureStyle: "renaissance_palace",
            culturalElements: ["paint_palette", "marble_sculpture", "fresco", "golden_ratio"]
        ),
        
        "arts_baroque": ClassroomEnvironmentConfig(
            setting: "baroque_cathedral",
            location: "Rome, Italy",
            timeperiod: "1650 CE",
            avatarRole: "baroque_architect",
            weatherSystem: "temperate",
            architectureStyle: "baroque_ornate",
            culturalElements: ["ornate_columns", "frescoed_ceiling", "marble_floors", "chandeliers"]
        ),
        
        "arts_impressionism": ClassroomEnvironmentConfig(
            setting: "impressionist_studio",
            location: "Paris, France",
            timeperiod: "1870 CE",
            avatarRole: "impressionist_painter",
            weatherSystem: "temperate",
            architectureStyle: "victorian_studio",
            culturalElements: ["water_lilies", "light_effects", "brush_techniques"]
        ),
        
        // PHILOSOPHY & SOCIAL SCIENCE
        "philosophy_stoicism": ClassroomEnvironmentConfig(
            setting: "ancient_stoic_school",
            location: "Athens, Greece",
            timeperiod: "300 BCE",
            avatarRole: "stoic_philosopher",
            weatherSystem: "mediterranean",
            architectureStyle: "greek_school",
            culturalElements: ["teaching_portico", "scrolls", "logic_puzzles"]
        ),
        
        // TECHNOLOGY & ENGINEERING
        "technology_industrial_revolution": ClassroomEnvironmentConfig(
            setting: "steam_mill_factory",
            location: "Manchester, England",
            timeperiod: "1800 CE",
            avatarRole: "industrial_engineer",
            weatherSystem: "smoky_industrial",
            architectureStyle: "victorian_factory",
            culturalElements: ["steam_engine", "textile_loom", "machinery", "coal_furnace"]
        ),
        
        "technology_modern_ai": ClassroomEnvironmentConfig(
            setting: "ai_research_lab",
            location: "Silicon Valley, California",
            timeperiod: "2025",
            avatarRole: "ai_researcher",
            weatherSystem: "temperate",
            architectureStyle: "tech_startup",
            culturalElements: ["server_farm", "gpu_cluster", "code_display", "neural_network"]
        )
    ]
    
    func mapCourseToEnvironment(_ course: Course) async throws -> ClassroomEnvironment {
        let key = "\(course.subject)_\(course.topic)".lowercased()
        
        guard let config = environmentMappings[key] else {
            // Fallback to generic environment
            print("⚠️ No mapping found for \(key), using generic environment")
            return ClassroomEnvironment(
                setting: "classroom_generic",
                location: "Learning Center",
                timeperiod: "present",
                avatarRole: "subject_expert",
                atmosphere: .neutral
            )
        }
        
        return ClassroomEnvironment(
            setting: config.setting,
            location: config.location,
            timeperiod: config.timeperiod,
            avatarRole: config.avatarRole,
            atmosphere: .immersive,
            weather: config.weatherSystem,
            culturalElements: config.culturalElements
        )
    }
}

// MARK: - Data Structures

struct ClassroomEnvironmentConfig {
    let setting: String
    let location: String
    let timeperiod: String
    let avatarRole: String
    let weatherSystem: String
    let architectureStyle: String
    let culturalElements: [String]
}

struct ClassroomEnvironment {
    let setting: String
    let location: String
    let timeperiod: String
    let avatarRole: String
    let atmosphere: AtmosphereType
    let weather: String?
    let culturalElements: [String]?
    
    var rawConfiguration: [String: Any] {
        [
            "setting": setting,
            "location": location,
            "timeperiod": timeperiod,
            "avatar_role": avatarRole,
            "atmosphere": atmosphere.rawValue,
            "weather": weather ?? "default",
            "cultural_elements": culturalElements ?? []
        ]
    }
}

enum AtmosphereType: String {
    case ceremonial
    case academic
    case experimental
    case cosmic
    case immersive
    case neutral
}

// MARK: - Helper Methods for Learning Resources
extension SubjectContextMapper {
    /// Gets the context for a subject/category string (used by LearningResources)
    func getContextForSubject(_ subject: String) -> (location: String, timePeriod: String, culturalElements: [String]) {
        let normalizedSubject = subject.lowercased()
        
        // History mappings
        if normalizedSubject.contains("maya") || normalizedSubject.contains("civilization") {
            let config = environmentMappings["history_maya"]!
            return (config.location, config.timeperiod, config.culturalElements)
        } else if normalizedSubject.contains("egypt") {
            let config = environmentMappings["history_egypt"]!
            return (config.location, config.timeperiod, config.culturalElements)
        } else if normalizedSubject.contains("rome") {
            let config = environmentMappings["history_rome"]!
            return (config.location, config.timeperiod, config.culturalElements)
        } else if normalizedSubject.contains("greece") {
            let config = environmentMappings["history_greece"]!
            return (config.location, config.timeperiod, config.culturalElements)
        } else if normalizedSubject.contains("viking") {
            let config = environmentMappings["history_viking"]!
            return (config.location, config.timeperiod, config.culturalElements)
        } else if normalizedSubject.contains("china") || normalizedSubject.contains("chinese") {
            let config = environmentMappings["history_china_imperial"]!
            return (config.location, config.timeperiod, config.culturalElements)
        }
        
        // Science mappings
        else if normalizedSubject.contains("chemistry") {
            let config = environmentMappings["science_chemistry"]!
            return (config.location, config.timeperiod, config.culturalElements)
        } else if normalizedSubject.contains("mars") || normalizedSubject.contains("space") {
            let config = environmentMappings["science_mars"]!
            return (config.location, config.timeperiod, config.culturalElements)
        } else if normalizedSubject.contains("rainforest") || normalizedSubject.contains("biology") {
            let config = environmentMappings["science_biology_rainforest"]!
            return (config.location, config.timeperiod, config.culturalElements)
        } else if normalizedSubject.contains("marine") || normalizedSubject.contains("ocean") {
            let config = environmentMappings["science_marine_biology"]!
            return (config.location, config.timeperiod, config.culturalElements)
        } else if normalizedSubject.contains("astronomy") || normalizedSubject.contains("stars") {
            let config = environmentMappings["science_astronomy"]!
            return (config.location, config.timeperiod, config.culturalElements)
        }
        
        // Default mapping
        else {
            return ("Modern Classroom", "2025", ["books", "whiteboard", "desk"])
        }
    }
}
