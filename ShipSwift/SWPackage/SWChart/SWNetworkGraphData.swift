//
//  SWNetworkGraphData.swift
//  ShipSwift
//
//  Full Marble Skill Taxonomy dataset for `SWNetworkGraph` — 1,590 micro-topics
//  across 8 subjects / 54 domains, wired by 3,221 prerequisite edges.
//  This is the same graph you can explore at https://withmarble.com/curriculum.
//
//  Data source & attribution (required by the license):
//    Marble Skill Taxonomy — https://github.com/withmarbleapp/os-taxonomy
//    (c) Marble, licensed under the Open Data Commons Open Database
//    License (ODbL) v1.0; topic content under CC BY-SA 4.0.
//    Fields used: id, name, subject, domain, ageRangeStart/End, centrality,
//    and the prerequisite edge list. Domain colors follow the palette of
//    the public visualization.
//
//  Storage format: the dataset is kept as compact pipe-separated rows in
//  string literals and parsed once on first access. Array literals of this
//  size (1,590 + 3,221 elements) would slow type checking to a crawl;
//  parsing the table at runtime takes a few milliseconds instead.
//
//  Regeneration: re-run the extraction against data/topics.json and
//  data/dependencies.json from the os-taxonomy repo, emitting one
//  `id|name|subject|domain|ageStart|ageEnd|centrality` row per topic and
//  one `topicId>prerequisiteId` row per dependency.
//
//  Usage:
//    SWNetworkGraph(
//        nodes: SWNetworkGraphData.nodes,
//        edges: SWNetworkGraphData.edges
//    )
//    .ignoresSafeArea()
//

import SwiftUI

enum SWNetworkGraphData {

    /// All 1,590 micro-topics as graph nodes. `level` is the topic's
    /// mid age normalized across the dataset (younger = lower in the funnel),
    /// `weight` is the topic's centrality in the prerequisite graph.
    static let nodes: [SWNetworkGraphNode] = {
        let rows = nodeTable.split(separator: "\n")
        var mids: [Double] = []
        mids.reserveCapacity(rows.count)
        var parsed: [(id: String, name: String, subject: String, domain: String,
                      ageStart: Int, ageEnd: Int, centrality: Double)] = []
        parsed.reserveCapacity(rows.count)
        for row in rows {
            let f = row.split(separator: "|", omittingEmptySubsequences: false)
            guard f.count == 7,
                  let ageStart = Int(f[4]), let ageEnd = Int(f[5]),
                  let centrality = Double(f[6]) else { continue }
            parsed.append((String(f[0]), String(f[1]), String(f[2]), String(f[3]),
                           ageStart, ageEnd, centrality))
            mids.append(Double(ageStart + ageEnd) / 2)
        }
        let minMid = mids.min() ?? 0
        let maxMid = mids.max() ?? 1
        let span = max(0.001, maxMid - minMid)
        return parsed.enumerated().map { i, t in
            SWNetworkGraphNode(
                id: t.id,
                title: t.name,
                subtitle: "age \(t.ageStart)\u{2013}\(t.ageEnd)",
                group: t.subject,
                color: color(hex: domainColors[t.domain] ?? "#8A8F98"),
                level: (mids[i] - minMid) / span,
                weight: t.centrality
            )
        }
    }()

    /// All 3,221 prerequisite edges (`from` builds on `to`).
    static let edges: [SWNetworkGraphEdge] = {
        edgeTable.split(separator: "\n").compactMap { row in
            let f = row.split(separator: ">")
            guard f.count == 2 else { return nil }
            return SWNetworkGraphEdge(from: String(f[0]), to: String(f[1]))
        }
    }()

    // MARK: - Colors

    /// One color per domain, following the public visualization palette.
    private static let domainColors: [String: String] = [
        "Addition & Subtraction": "#5763E7",
        "Algebra": "#FFFFFF",
        "Ancient Egypt": "#F3EBDC",
        "Ancient Greece & Rome": "#F6EADF",
        "Animals of the World": "#8DA2D4",
        "Artificial Intelligence": "#1B26B4",
        "Counting & Cardinality": "#2D39E7",
        "Data & Statistics": "#2D3BE8",
        "Dinosaurs & Paleontology": "#A1BFE4",
        "Earth's Systems": "#A0B2E4",
        "Ecosystems & Habitats": "#9DC0DF",
        "Emotional Literacy": "#ED4640",
        "Empathy & Social Awareness": "#E92925",
        "Energy": "#87ADE3",
        "English Thinking": "#F44D8F",
        "Entrepreneurship": "#E9C0D0",
        "Forces & Motion": "#8EBBDE",
        "Fractions": "#FFD9D2",
        "Friendship & Cooperation": "#F25B45",
        "Geometry": "#568AE3",
        "Grammar & Punctuation": "#F08DA0",
        "Handwriting & Transcription": "#EA6C87",
        "Historical Thinking": "#F0E9D9",
        "Insects & Minibeasts": "#80A8DB",
        "Learning to Learn": "#EBB39D",
        "Mathematical Thinking": "#5081EF",
        "Matter & Materials": "#8CA5D7",
        "Measurement": "#4E6CF1",
        "Medieval Times": "#EEE0C5",
        "Money & Finance": "#E8BECE",
        "Multiplication & Division": "#4588F4",
        "Number Representation & Place Value": "#5277E9",
        "Ocean Life": "#94BCE2",
        "Organisms & Life Processes": "#9EB7E1",
        "Phonics & Word Reading": "#F65481",
        "Polar Regions": "#9DC1E6",
        "Probability": "#3B4FEF",
        "Rainforests": "#90A8E1",
        "Ratio & Proportion": "#3161ED",
        "Reading Comprehension": "#EB547D",
        "Responsible Decision-Making": "#F84720",
        "Scientific Inquiry": "#9AB0E4",
        "Self-Awareness": "#EF451C",
        "Self-Regulation & Resilience": "#EB532D",
        "Space Exploration": "#95AEE0",
        "Space Systems & Earth's History": "#ABC5E6",
        "Speaking & Listening": "#F65C79",
        "Spelling & Word Study": "#EB6A87",
        "The Human Body": "#AAC5E3",
        "Vocabulary": "#EE809A",
        "Volcanoes & Earthquakes": "#A5BCDF",
        "Waves, Light & Sound": "#AFC2E5",
        "Weather & Climate": "#9AB2E2",
        "Writing Composition": "#EB6B82",
    ]

    private static func color(hex: String) -> Color {
        var value: UInt64 = 0
        Scanner(string: String(hex.dropFirst())).scanHexInt64(&value)
        return Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    // MARK: - Tables

    /// `id|name|subject|domain|ageStart|ageEnd|centrality`, one topic per row.
    private static let nodeTable = """
mt_AzTrT5ySCx|AI in Daily Life|Computing|Artificial Intelligence|5|7|0.027
mt_XbGfVhfiUz|Computers in Everyday Life|Computing|Artificial Intelligence|5|7|0.029
mt_jvJ35MmCvK|Real-World Robots|Computing|Artificial Intelligence|5|7|0.01
mt_WRRv1ABECC|Smart Versus Not-Smart Devices|Computing|Artificial Intelligence|5|7|0.026
mt__p5n8z5soJ|Step-by-Step Instructions|Computing|Artificial Intelligence|5|7|0.026
mt_u6SYiVx7FX|Voice Assistants and How They Work|Computing|Artificial Intelligence|5|7|0.027
mt_fT4G0QloX5|AI in Computer Games|Computing|Artificial Intelligence|7|9|0.01
mt_bPFToj0OhZ|AI Mistakes and Limitations|Computing|Artificial Intelligence|7|9|0.023
mt_kH1DzOPsXG|Data and Information for Computers|Computing|Artificial Intelligence|7|9|0.027
mt_oajUvqAiBJ|Humans Versus Machines|Computing|Artificial Intelligence|7|9|0.019
mt_K6qtan847r|Machine Learning Basics|Computing|Artificial Intelligence|7|9|0.025
mt_ofOGCQ7FWj|Patterns and Classification|Computing|Artificial Intelligence|7|9|0.027
mt_EedcpioR0v|Recommendation Systems and Filter Bubbles|Computing|Artificial Intelligence|7|9|0.011
mt_cVp_nop-5L|AI and Fairness in Decisions|Computing|Artificial Intelligence|9|11|0.021
mt_ZpCcTU8j_o|AI and the Environment|Computing|Artificial Intelligence|9|11|0.111
mt__AWSThGJ0d|AI and the Future of Work|Computing|Artificial Intelligence|9|11|0.021
mt_HopZomN12L|AI Data Collection and Privacy|Computing|Artificial Intelligence|9|11|0.031
mt__BbOjiY5A5|Bias in AI Systems|Computing|Artificial Intelligence|9|11|0.019
mt_tzMr83pS8v|Deepfakes and AI-Generated Content|Computing|Artificial Intelligence|9|11|0.015
mt_1z-gJBJFlM|Designing Fair AI Rules|Computing|Artificial Intelligence|9|11|0.021
mt__LiAEHt9nk|The Future of AI|Computing|Artificial Intelligence|9|11|0.115
mt_scBgiMKhG_|Reading for Meaning|English|English Thinking|5|6|0.114
mt_GugVunb2lI|Monitoring Comprehension|English|English Thinking|6|8|0.111
mt_QB4qIGJIIj|Author's word choices|English|English Thinking|7|9|0.055
mt_lp3qyEujIv|Inference vs Explicit Meaning|English|English Thinking|7|9|0.033
mt_LH714Riydn|Knowing What You Don't Know|English|English Thinking|8|10|0.038
mt_U_8iVFZuHH|Reviewing Own Writing|English|English Thinking|8|10|0.062
mt_haNr13NIuN|Reflecting on Your Language Use|English|English Thinking|10|11|0.045
mt_N8CpN1EJrP|Building sentences|English|Grammar & Punctuation|4|6|0.257
mt_of2GggtxFl|Spaces Between Words|English|Grammar & Punctuation|4|6|0.003
mt_yBJyCfhtem|Basic Nouns & Verbs|English|Grammar & Punctuation|5|6|0.088
mt_uM6q_KBWKy|Capitals for Names, Days and I|English|Grammar & Punctuation|5|7|0.003
mt_TfOiog-ALs|Grammar words: letter, word, sentence|English|Grammar & Punctuation|5|6|0.034
mt_YXVQaufkKO|Joining Words with 'And'|English|Grammar & Punctuation|5|7|0.059
mt_VY3rBq8RyP|Prepositions|English|Grammar & Punctuation|5|7|0.037
mt_6lHBTwQPrS|Question Words|English|Grammar & Punctuation|5|6|0.067
mt_18qkgxr_-T|Regular Plural Nouns|English|Grammar & Punctuation|5|6|0.042
mt_QEr24lqzvH|Starting and Ending Sentences|English|Grammar & Punctuation|5|8|0.094
mt_mKAZTqItRG|Apostrophes: Contraction and Possession|English|Grammar & Punctuation|6|7|0.056
mt_ntqNLHsj5n|Commas in lists|English|Grammar & Punctuation|6|11|0.067
mt_RioBUxHz1X|Determiners and articles|English|Grammar & Punctuation|6|7|0.003
mt_cU3LcEVkBQ|Expanded noun phrases|English|Grammar & Punctuation|6|7|0.052
mt_u1-UfD0rTH|Four Types of Sentences|English|Grammar & Punctuation|6|7|0.081
mt_qzwQAOfurw|Grammar Terms: Nouns, Verbs and Tense|English|Grammar & Punctuation|6|7|0.067
mt_enj1sMcfOT|Past, Present and Progressive Tense|English|Grammar & Punctuation|6|9|0.112
mt_sZXPK1FnRB|Pronouns|English|Grammar & Punctuation|6|7|0.034
mt_u7Jxjjatkh|Subject-verb agreement|English|Grammar & Punctuation|6|7|0.018
mt_wq-1OJ_8s5|Subordinate clauses|English|Grammar & Punctuation|6|9|0.063
mt_j351evNNnB|Adjectives vs adverbs|English|Grammar & Punctuation|7|8|0.014
mt_2l06snztdP|Choosing A or An|English|Grammar & Punctuation|7|8|0.003
mt_uorNrPTh6U|Expressing Time, Place and Cause|English|Grammar & Punctuation|7|8|0.034
mt_B8JOz79O6t|Grammar Terms: Clauses and Conjunctions|English|Grammar & Punctuation|7|9|0.055
mt_KIG5FQI5fC|Irregular past tense verbs|English|Grammar & Punctuation|7|8|0.094
mt_nFBLNoChD0|Irregular Plural Nouns|English|Grammar & Punctuation|7|9|0.004
mt_9yFAtUkoYr|Pronouns for clarity|English|Grammar & Punctuation|7|9|0.034
mt_-mw3JeIjhU|Punctuating Direct Speech|English|Grammar & Punctuation|7|10|0.023
mt_7D-vlii8F-|The Present Perfect Tense|English|Grammar & Punctuation|7|11|0.101
mt_8bIXVKTdtK|Abstract nouns|English|Grammar & Punctuation|8|9|0.001
mt_2NfIKEYdbm|Agreement in sentences|English|Grammar & Punctuation|8|10|0.008
mt_X1L9DoUwjF|Comparatives & Superlatives|English|Grammar & Punctuation|8|9|0.014
mt_EbiGRVK8uR|Expanded noun phrases (age 8+)|English|Grammar & Punctuation|8|10|0.023
mt_0QJoKWABdC|Fronted Adverbials and Commas|English|Grammar & Punctuation|8|9|0.034
mt_J5cx6S_eT9|Grammar Terms: Pronouns and Determiners|English|Grammar & Punctuation|8|9|0.049
mt_bn5ggh84qD|Plural vs Possessive in Nouns|English|Grammar & Punctuation|8|9|0.025
mt_Of-WsrRQ8B|Simple Past, Present and Future|English|Grammar & Punctuation|8|9|0.101
mt_ay0qkGj0jg|Standard English Verbs|English|Grammar & Punctuation|8|9|0.096
mt_VVx0hPPSKi|Adjective Order in Sentences|English|Grammar & Punctuation|9|10|0.018
mt_m3-eXac3aP|Brackets and dashes for parenthesis|English|Grammar & Punctuation|9|10|0.022
mt_4-vfMgmCVB|Cohesion within paragraphs|English|Grammar & Punctuation|9|11|0.059
mt_j2idD_jq73|Commas Before Joining Words|English|Grammar & Punctuation|9|11|0.012
mt_VMS3kDQ8sA|Commas to avoid ambiguity|English|Grammar & Punctuation|9|10|0.014
mt_p3tZiUaWAa|Converting Words into Verbs|English|Grammar & Punctuation|9|10|0.018
mt_7SfQuXgNtd|Expanded noun phrases (age 9+)|English|Grammar & Punctuation|9|10|0.025
mt_7oZ2YenzhX|Fixing Fragments & Run-Ons|English|Grammar & Punctuation|9|10|0.008
mt_-tcJeAhK5k|Grammar Terms: Modal Verbs and Clauses|English|Grammar & Punctuation|9|10|0.049
mt_uvILgZq9HN|Linking paragraphs with adverbials|English|Grammar & Punctuation|9|11|0.07
mt_N9zffZxuu5|Modal Verbs and Possibility|English|Grammar & Punctuation|9|10|0.1
mt_mkDqmejLMw|Progressive and Continuous Tenses|English|Grammar & Punctuation|9|10|0.098
mt_YQ64pzcLDl|Relative Clauses|English|Grammar & Punctuation|9|10|0.021
mt_qw6mhOl-Qy|Verb Prefixes and Meaning|English|Grammar & Punctuation|9|10|0.018
mt_gbTyzvnWzr|Active and passive voice|English|Grammar & Punctuation|10|11|0.103
mt_wUyAZJikAA|Bullet Point Punctuation|English|Grammar & Punctuation|10|11|0.005
mt_mpktt3wj1M|Choosing Tenses for Precise Meaning|English|Grammar & Punctuation|10|11|0.101
mt_uycuqPaiJ1|Colons and Semicolons in Lists|English|Grammar & Punctuation|10|11|0.007
mt_0wUwxyBs5y|Commas After Introductory Elements|English|Grammar & Punctuation|10|11|0.014
mt_AfIzLRvMgW|Commas with yes, no, and names|English|Grammar & Punctuation|10|11|0.021
mt_LN_g2b3d34|Conjunctions, Prepositions and Interjections|English|Grammar & Punctuation|10|11|0.011
mt_npRaYRhU2V|Consistent verb tense|English|Grammar & Punctuation|10|11|0.101
mt_S7CnyZCnxg|Correlative Conjunctions|English|Grammar & Punctuation|10|11|0.008
mt_hzkNpp2PdV|Grammar Terms: Voice and Punctuation|English|Grammar & Punctuation|10|11|0.107
mt_QpmVikVaqY|Hyphens in Prefixed Words|English|Grammar & Punctuation|10|11|0.022
mt_hjtbA3g-Nn|Paragraph Cohesion|English|Grammar & Punctuation|10|11|0.07
mt_xYjD_kA70s|Punctuating Clauses|English|Grammar & Punctuation|10|11|0.012
mt_Q2Eud_PPz6|Punctuating Titles of Works|English|Grammar & Punctuation|10|11|0.019
mt_k7VtbWdfDO|The subjunctive mood|English|Grammar & Punctuation|10|11|0.011
mt_ZO2iP89cld|Varying Sentence Structure|English|Grammar & Punctuation|10|11|0.014
mt_lsO9O-_eZH|Advanced Punctuation for Clarity|English|Grammar & Punctuation|11|14|0.029
mt_N5tiL3uIeq|Grammar for Effect|English|Grammar & Punctuation|11|14|0.12
mt_HCweOHWSiu|Literary and Language Terminology|English|Grammar & Punctuation|11|14|0.115
mt_IdFxLz-UW9|Phrases & Clauses|English|Grammar & Punctuation|11|13|0.03
mt_S2fP8rUwrl|Standard English|English|Grammar & Punctuation|11|13|0.018
mt_T9IXrlxfx2|Types of Sentences|English|Grammar & Punctuation|11|14|0.027
mt_N5tciHU8cE|Verb Voice and Mood|English|Grammar & Punctuation|12|14|0.103
mt_WBfj79OqXz|Sitting and holding a pencil|English|Handwriting & Transcription|4|6|0.665
mt_H7DquwQi_F|Forming Capital Letters|English|Handwriting & Transcription|5|6|0.053
mt_DMvKfP4uGC|Letter Formation Families|English|Handwriting & Transcription|5|6|0.001
mt_oAK9GXSfqV|Writing digits 0-9|English|Handwriting & Transcription|5|6|0.59
mt_02DH7sGXCi|Joining Letters|English|Handwriting & Transcription|6|10|0.053
mt__KHQttMde3|Blending Sounds to Read Words|English|Phonics & Word Reading|4|7|0.164
mt_9-OHslmt1g|Consonant Digraphs|English|Phonics & Word Reading|4|7|0.126
mt_frDIaXzWbx|Knowing all letters|English|Phonics & Word Reading|4|6|0.212
mt_PvU3eoikev|Onsets & Rimes|English|Phonics & Word Reading|4|7|0.187
mt_4GiE83rJF_|Rhyming words|English|Phonics & Word Reading|4|6|0.187
mt_F978c32kDr|Single Letter Sounds|English|Phonics & Word Reading|4|6|0.196
mt_1KCwbGvm1F|Understanding print|English|Phonics & Word Reading|4|6|0.252
mt_BtMbZibZUj|Vowel Digraphs|English|Phonics & Word Reading|4|7|0.129
mt_70Ys4i1AB1|Compound Words|English|Phonics & Word Reading|5|8|0.011
mt_fMd7v87IiI|Diphthongs and complex vowels|English|Phonics & Word Reading|5|6|0.005
mt_a6m7PqTuJN|R-Controlled Vowel Sounds|English|Phonics & Word Reading|5|6|0.004
mt_t1JXeNgKcu|Reading Contractions|English|Phonics & Word Reading|5|6|0.048
mt_ZhvwM6LMBL|Reading fluently|English|Phonics & Word Reading|5|7|0.103
mt_YKkCM63fSC|Reading High-Frequency Words by Sight|English|Phonics & Word Reading|5|8|0.111
mt__CMXZiPfTV|Reading Inflectional Endings|English|Phonics & Word Reading|5|7|0.011
mt_C7abt7pRr6|Split Digraphs and Magic E|English|Phonics & Word Reading|5|7|0.005
mt_UvNrOXny1i|Syllables|English|Phonics & Word Reading|5|6|0.186
mt_roAgL1rQRF|Trigraphs|English|Phonics & Word Reading|5|6|0.007
mt_OgJPbGkrYk|Alternative Spellings for Known Sounds|English|Phonics & Word Reading|6|8|0.131
mt_V-ldQp56bF|Reading with Expression and Accuracy|English|Phonics & Word Reading|6|10|0.103
mt_kVzAFMuFc4|Syllables (age 6+)|English|Phonics & Word Reading|6|9|0.014
mt_14OR-MhGJ9|Decoding unfamiliar words|English|Phonics & Word Reading|7|9|0.011
mt_HrgDjxcWvf|Prefixes and suffixes|English|Phonics & Word Reading|7|9|0.011
mt_8-POYyg7GJ|Predicting what happens next|English|Reading Comprehension|4|10|0.053
mt_XeMZdf2Y9W|Book Features and Author's Reasons|English|Reading Comprehension|5|8|0.079
mt_sSQlLOnAow|Characters, settings, and events|English|Reading Comprehension|5|8|0.153
mt_GLY3R3YSlf|Comparing Characters Across Stories|English|Reading Comprehension|5|9|0.037
mt_5n-O41lUgn|Connecting reading to experience|English|Reading Comprehension|5|7|0.016
mt_gZIo5oiBMt|Different Types of Texts|English|Reading Comprehension|5|7|0.008
mt_thsY1ZesaU|Discussing Texts as a Group|English|Reading Comprehension|5|10|0.016
mt_mLPEMpYb_R|Listening to Texts Read Aloud|English|Reading Comprehension|5|10|0.25
mt_aFvsj35QzC|Main Topic of Informational Texts|English|Reading Comprehension|5|7|0.111
mt_OlhMP7ShFT|Pictures and Text Working Together|English|Reading Comprehension|5|9|0.005
mt_E5KC4AnRLW|Reading between the lines|English|Reading Comprehension|5|10|0.096
mt_rQ2YJJi4uh|Self-Correcting While Reading|English|Reading Comprehension|5|11|0.09
mt_xjl6AEhnjk|Characters' Viewpoints and Responses|English|Reading Comprehension|6|8|0.053
mt_fL1Xz8ostr|Expressive and Sensory Language|English|Reading Comprehension|6|9|0.042
mt_QCWWmDMYZR|Main Topic & Key Details|English|Reading Comprehension|6|10|0.025
mt_ZhUuT__i2H|Non-Fiction Text Features|English|Reading Comprehension|6|9|0.066
mt_zlSoIKPyId|Retelling Stories with Structure|English|Reading Comprehension|6|8|0.045
mt_VEwM7ClYYE|Story Sequence and Central Message|English|Reading Comprehension|6|8|0.09
mt_gR5_n99Ntt|Forms of Poetry and Performance|English|Reading Comprehension|7|10|0.047
mt_ukLvUD8DFA|Inferring Characters' Feelings and Motives|English|Reading Comprehension|7|10|0.092
mt_sMAcZW6vWM|Main Ideas & Note-Taking|English|Reading Comprehension|7|10|0.063
mt_v33BwiyRnd|Story Lessons and Morals|English|Reading Comprehension|7|8|0.038
mt_aVZJhPbc_1|Text Features & Presentation|English|Reading Comprehension|7|10|0.033
mt_yHQacItlhf|Themes and messages|English|Reading Comprehension|7|10|0.041
mt_KmPZ5diLEP|Character Traits and Motivation|English|Reading Comprehension|8|9|0.07
mt_w4wKFP3jud|Connecting Ideas in Texts|English|Reading Comprehension|8|9|0.026
mt_H0ajATAlus|Morals in Fables, Folktales and Myths|English|Reading Comprehension|8|9|0.031
mt_ujwtRoYJ34|Structural terminology|English|Reading Comprehension|8|9|0.023
mt_OltpfaX7l6|Why the author wrote it|English|Reading Comprehension|8|9|0.026
mt_8FwtdJzeDh|Combining information from texts|English|Reading Comprehension|9|10|0.021
mt_ZanQuV90qi|Cultural Allusions and Word Meaning|English|Reading Comprehension|9|10|0.011
mt_nKS_vCYrg3|Explaining Events & Ideas|English|Reading Comprehension|9|10|0.019
mt_A0htaNaK7b|Finding Theme and Summarising|English|Reading Comprehension|9|11|0.045
mt_j32D5DZX7x|Firsthand and Secondhand Accounts|English|Reading Comprehension|9|10|0.005
mt_k-V37x3zsF|How authors support their points|English|Reading Comprehension|9|10|0.005
mt_Eehl12cSnN|In-Depth Character and Setting Analysis|English|Reading Comprehension|9|10|0.067
mt_KbCCmLmxYN|Interpreting visual information in texts|English|Reading Comprehension|9|10|0.019
mt_E_OryWIYkn|Narrator's Point of View|English|Reading Comprehension|9|10|0.067
mt_4IxR66uGLc|Poems, Drama & Prose|English|Reading Comprehension|9|10|0.053
mt_0MfpLj0Uhb|Recommending Books|English|Reading Comprehension|9|10|0.067
mt_oVwNnjYPUY|Structure of information texts|English|Reading Comprehension|9|10|0.034
mt_t06dHX2ZYw|Text & Media Connections|English|Reading Comprehension|9|10|0.003
mt_tX0R4-4WXy|Themes Across Cultures and Traditions|English|Reading Comprehension|9|10|0.031
mt_sUVOS2jH3J|Comparing Books|English|Reading Comprehension|10|11|0.066
mt_WRlJ0-hAOG|Comparing Characters, Settings and Events|English|Reading Comprehension|10|11|0.067
mt_-1okUh0Jdv|Comparing Structure in Information Texts|English|Reading Comprehension|10|11|0.034
mt_LCJNRaRXtW|Different viewpoints in texts|English|Reading Comprehension|10|11|0.067
mt_iv-BJS9W60|Explaining Relationships in Texts|English|Reading Comprehension|10|11|0.019
mt_V6456X6pJE|Fact vs opinion|English|Reading Comprehension|10|11|0.012
mt_jO0gHMk7Ti|How Authors Treat Similar Themes|English|Reading Comprehension|10|11|0.031
mt_furAIwoO9t|How Language Choices Affect the Reader|English|Reading Comprehension|10|11|0.023
mt_PetJM-AYz9|How Parts Build a Whole Text|English|Reading Comprehension|10|11|0.019
mt_IX37F4rNed|Justifying Views About Texts|English|Reading Comprehension|10|11|0.174
mt_xsk3iuNVVI|Multimedia elements in texts|English|Reading Comprehension|10|11|0.003
mt_5FREdVoS8s|Multiple Accounts of Events|English|Reading Comprehension|10|11|0.005
mt_ak_ZgoMKRQ|Quoting Accurately from Texts|English|Reading Comprehension|10|11|0.044
mt_XnRhhEqJLJ|Summarising Non-Fiction Main Ideas|English|Reading Comprehension|10|11|0.037
mt_S3XMQOYt_D|Supporting ideas with evidence|English|Reading Comprehension|10|11|0.005
mt_kJ4xXKL_nO|Synthesising across multiple texts|English|Reading Comprehension|10|11|0.021
mt_JVVKT-_AD9|Using Multiple Sources|English|Reading Comprehension|10|11|0.073
mt_II6iw4BmJI|Analysing Text Structure|English|Reading Comprehension|11|14|0.016
mt_1GF5MeNZPA|Critical comparison across texts|English|Reading Comprehension|11|14|0.078
mt_gMSFymQlrW|Evaluating Arguments in Non-Fiction|English|Reading Comprehension|11|14|0.174
mt_DVSHx3YMkN|Figurative Language and Literary Devices|English|Reading Comprehension|11|14|0.174
mt_x2sWtfTeYT|Narrative Perspective and Unreliable Narrators|English|Reading Comprehension|11|14|0.161
mt_Hqz5y_tWz2|Plot Structure and Character Development|English|Reading Comprehension|11|14|0.161
mt_aClzPBiS9k|Poetic forms and conventions|English|Reading Comprehension|11|14|0.172
mt_jIcgbCmziD|Purpose, audience, and context|English|Reading Comprehension|11|14|0.026
mt_wGxq92Na5g|Tracing Theme Across a Text|English|Reading Comprehension|11|14|0.045
mt_tIi6L1n7kF|Understanding drama and performance|English|Reading Comprehension|11|14|0.161
mt_dmFnJzxKwz|Using and Evaluating Textual Evidence|English|Reading Comprehension|11|14|0.174
mt_9k1qcpvVi_|Wide Independent Reading Across Genres|English|Reading Comprehension|11|14|0.064
mt_f8n4txtLej|Asking Questions|English|Speaking & Listening|4|11|0.071
mt_4A7FYmvVhA|Describing Aloud|English|Speaking & Listening|4|8|0.156
mt_n6GhzDPllD|Exploring Ideas Through Talk|English|Speaking & Listening|4|6|0.204
mt_S0hzjAeLSK|Expressing & Justifying Opinions|English|Speaking & Listening|4|6|0.149
mt_wwdRhPyz6s|Group discussions|English|Speaking & Listening|4|11|0.164
mt_mB7DVai-Uf|Listening and responding|English|Speaking & Listening|4|11|0.301
mt_ZBMcX2oRor|Reciting Poetry|English|Speaking & Listening|6|10|0.037
mt_sXRHr7tfS5|Engaging Listeners and Valuing Viewpoints|English|Speaking & Listening|7|8|0.052
mt_yrMniCJu_S|Preparing for and Explaining in Discussions|English|Speaking & Listening|8|11|0.037
mt_ds2TOtP8I1|Reporting & Recounting|English|Speaking & Listening|8|11|0.011
mt_iodbOOmEQs|Identifying Reasons Behind a Speaker's Points|English|Speaking & Listening|9|10|0.047
mt_-DuXzMVVXQ|Paraphrasing What You Hear|English|Speaking & Listening|9|10|0.038
mt_bkvB7QYKwg|Adapting Speech to Context|English|Speaking & Listening|10|11|0.015
mt_LNYTNpJOGT|Building on Others in Discussions|English|Speaking & Listening|10|11|0.008
mt_Cc-QHVo747|Drawing Conclusions from Discussion|English|Speaking & Listening|10|11|0.037
mt_on7FHCDmi-|Evaluating a Speaker's Argument|English|Speaking & Listening|10|11|0.041
mt_VtqvUORa8K|Multimedia Presentations|English|Speaking & Listening|10|11|0.011
mt_A4YUbzUFan|Summarising Spoken and Media Presentations|English|Speaking & Listening|10|11|0.038
mt_ylFTYS80d1|Performing Scripts & Poetry|English|Speaking & Listening|11|14|0.161
mt_z07UNAIsNc|Speaking Formally and Giving Presentations|English|Speaking & Listening|11|14|0.018
mt_Yrjn8jAt1c|Formal Debates|English|Speaking & Listening|12|14|0.241
mt_EqXlZfB4jp|Phonics Vocabulary|English|Spelling & Word Study|4|7|0.077
mt_BhYJZUsErp|Segmenting words into sounds|English|Spelling & Word Study|4|7|0.086
mt_AhfyJoTQtY|Spelling from Dictation|English|Spelling & Word Study|5|8|0.016
mt_QdMMLRYWhn|Spelling Verb Endings|English|Spelling & Word Study|5|6|0.034
mt_zBUcAPDRPM|The Prefix un-|English|Spelling & Word Study|5|6|0.018
mt_Jq0MjURrRC|Tricky words|English|Spelling & Word Study|5|8|0.018
mt_p_jxNLdus4|Alternative Spellings for Sounds|English|Spelling & Word Study|6|9|0.048
mt_Z3G_97fnha|Apostrophes for possession|English|Spelling & Word Study|6|8|0.055
mt_IntmJBg4VQ|Spelling Contracted Forms|English|Spelling & Word Study|6|7|0.052
mt_FYK8m6eHQm|Suffixes|English|Spelling & Word Study|6|7|0.034
mt_HdI1y5KsBl|Apostrophes for possession (age 7+)|English|Spelling & Word Study|7|10|0.022
mt_37QCuGOxFe|Homophones|English|Spelling & Word Study|7|9|0.022
mt_T6nrrf2K43|Prefixes (age 7+)|English|Spelling & Word Study|7|10|0.021
mt_O2dS6gvClw|Spelling Word Lists (age 7+)|English|Spelling & Word Study|7|9|0.023
mt_tHtjfjjFrl|Suffixes (age 7+)|English|Spelling & Word Study|7|9|0.027
mt_6W5zzDIGZH|Using a Dictionary to Check Spellings|English|Spelling & Word Study|7|11|0.012
mt_y8sicbhMci|Spellings from Greek, French and Latin|English|Spelling & Word Study|8|10|0.023
mt_U_HQXCnAaG|Advanced Spelling Conventions|English|Spelling & Word Study|9|10|0.021
mt_u3OuIXqmAo|Homophones (age 9+)|English|Spelling & Word Study|9|10|0.022
mt_XK7NYt61cO|Silent Letters in Words|English|Spelling & Word Study|9|10|0.018
mt_9hBs430cU4|Spelling -able & -ible|English|Spelling & Word Study|9|10|0.016
mt_sJyZW4qYUG|Spelling Word Lists (age 9+)|English|Spelling & Word Study|9|10|0.023
mt_2X9Cd38eSJ|Suffixes (age 9+)|English|Spelling & Word Study|9|10|0.016
mt_4PA9IrxtCQ|Applying Spelling Rules to Complex Words|English|Spelling & Word Study|11|14|0.029
mt_6-MYToNZ39|Discussing and Questioning New Words|English|Vocabulary|5|11|0.17
mt_VLu59hpQ4T|Shades of Meaning|English|Vocabulary|5|9|0.045
mt_oL9s_bufDp|Sorting & Categorising Words|English|Vocabulary|5|8|0.155
mt_NP101Zl-4g|Using New Vocabulary|English|Vocabulary|5|9|0.03
mt_aw0PldeT_L|Word Parts as Clues|English|Vocabulary|5|8|0.005
mt_f_dMmvzxwo|Defining Words|English|Vocabulary|6|9|0.127
mt_UEe3MC5RZc|Root Words & Inflections|English|Vocabulary|6|9|0.021
mt_86DyHo9zO3|Formal and Informal English|English|Vocabulary|7|10|0.04
mt_p1imGSFgJT|Word Families and Root Words|English|Vocabulary|7|9|0.021
mt_SUOhjmRqv9|Literal vs Figurative Language|English|Vocabulary|8|9|0.026
mt_E5YbLvMgLL|Antonyms & Synonyms|English|Vocabulary|9|11|0.011
mt_WzOyJFKDIu|Domain Vocabulary Across Subject Areas|English|Vocabulary|9|11|0.083
mt_x_Lg4RASVU|Greek and Latin Roots for Word Meaning|English|Vocabulary|9|11|0.023
mt_IoGOSAQ8bz|Idioms & Proverbs|English|Vocabulary|9|11|0.011
mt_hJW7hVflm3|Similes & Metaphors|English|Vocabulary|9|11|0.023
mt_h3vmvQW5Wa|Choosing Formal Vocabulary|English|Vocabulary|10|11|0.022
mt_1ro8W1cZYn|Dialects & Registers|English|Vocabulary|10|11|0.014
mt_saW7PxtPxw|Using a Thesaurus to Choose Words|English|Vocabulary|10|11|0.019
mt_OLwNsTI6C7|Academic Vocabulary|English|Vocabulary|11|14|0.049
mt_MlmIrLb_7x|Advanced Figurative Language|English|Vocabulary|11|14|0.167
mt_WZnwITSWr8|Vocabulary Strategies|English|Vocabulary|11|14|0.034
mt_OyOYHlZ2_T|Responding to Writing Feedback|English|Writing Composition|5|7|0.077
mt_PJyCGJz5Hv|Saying Sentences Before Writing Them|English|Writing Composition|5|6|0.112
mt_4A4RpX-Go9|Shared Research Projects|English|Writing Composition|5|9|0.021
mt_nYU6x2E2T8|Sharing and Publishing Your Writing|English|Writing Composition|5|11|0.016
mt_nDAcXoPa0c|Simple Stories with Beginning and Ending|English|Writing Composition|5|7|0.098
mt_91f1XFvGZq|Writing opinions|English|Writing Composition|5|7|0.026
mt_o8ciHks8t2|Writing Process Vocabulary|English|Writing Composition|5|8|0.112
mt__MDiDU9Vck|Writing to inform|English|Writing Composition|5|7|0.066
mt_hp2qJ-QRBn|Basic Informational Writing|English|Writing Composition|6|11|0.026
mt_lIs10UMkPG|Building Writing Stamina|English|Writing Composition|6|7|0.083
mt_9P9o6d0Qm3|Planning Ideas Before Writing|English|Writing Composition|6|10|0.062
mt_I65kFjWwnF|Revising and editing|English|Writing Composition|6|7|0.094
mt_WKxX-b86Vr|Structured Opinion Writing|English|Writing Composition|6|11|0.019
mt_YNe6siFTFq|Writing Poetry|English|Writing Composition|6|7|0.03
mt_vauULTecMH|Narrative Writing|English|Writing Composition|7|11|0.033
mt_AvJMWQbDsr|Organising Writing into Paragraphs|English|Writing Composition|7|10|0.068
mt_FGCFUCqJBB|Rehearsing and Varying Sentences|English|Writing Composition|7|8|0.029
mt_pis4novXWQ|Revising and editing (age 7+)|English|Writing Composition|7|11|0.082
mt_HWYAspz-LK|Revising and editing (age 8+)|English|Writing Composition|8|9|0.071
mt_FW9_8F52bw|Short Research Projects|English|Writing Composition|8|11|0.071
mt_LMX-nZETLM|Vivid Word Choices|English|Writing Composition|8|10|0.027
mt_82KKv0Fca3|Writing Craft Vocabulary|English|Writing Composition|8|11|0.047
mt_v5DyOEpbbr|Choosing Form and Tone for Your Audience|English|Writing Composition|9|10|0.07
mt_ZxdfRbwkKM|Evidence-Based Writing|English|Writing Composition|9|11|0.068
mt_sdmm_m60qX|Literary Evidence in Writing|English|Writing Composition|9|11|0.067
mt_cB7hV8sw7X|Writing for an audience|English|Writing Composition|9|11|0.049
mt_AHAFw-atka|Layout and Formatting in Informational Writing|English|Writing Composition|10|11|0.042
mt_j6ENpc8--_|Planning Narratives|English|Writing Composition|10|11|0.066
mt_dRLP8g0SAg|Research & Note-Taking|English|Writing Composition|10|11|0.06
mt_curkA82CmO|Writing a Précis|English|Writing Composition|10|11|0.041
mt_tn1rY9GbEZ|Cohesion and Transitions Across Writing|English|Writing Composition|11|14|0.07
mt_zCUIJLdK_s|Developed Informational and Explanatory Writing|English|Writing Composition|11|14|0.082
mt_Qxyikkkzam|Persuasive Writing|English|Writing Composition|11|14|0.239
mt_av-uRBrhwT|Planning, Revising and Editing Writing|English|Writing Composition|11|14|0.129
mt_Qcsl1Z1x0l|Research & Source Evaluation|English|Writing Composition|11|14|0.135
mt_9lN0SpKlEH|Writing Across Genres|English|Writing Composition|11|14|0.088
mt_BLzNxSSdWu|Writing Character & Dialogue|English|Writing Composition|11|14|0.088
mt_s6-6FYb5UQ|Writing Techniques for Effect|English|Writing Composition|11|14|0.228
mt_IR8kIjZn_V|Discovering Tutankhamun's Tomb|History|Ancient Egypt|5|7|0.019
mt_bvxkT1nepy|Egyptian Gods and the Afterlife|History|Ancient Egypt|5|7|0.044
mt_8UL1opbJEt|Egypt, the Nile, and the Desert|History|Ancient Egypt|5|7|0.064
mt_P0HBNfp46z|Everyday Life in Ancient Egypt|History|Ancient Egypt|5|7|0.041
mt_iFkd0CTwlA|Hieroglyphs and Papyrus|History|Ancient Egypt|5|7|0.021
mt_E7avIa-tcE|Pharaohs and Tutankhamun|History|Ancient Egypt|5|7|0.055
mt_mmudyxf7bT|Pyramids and the Great Sphinx|History|Ancient Egypt|5|7|0.048
mt_szw1Ln490b|Vocabulary: ancient egypt|History|Ancient Egypt|5|9|0.057
mt_pTz6u49fQt|Ancient Egypt on the Timeline|History|Ancient Egypt|7|9|0.082
mt_kgTN6yk4oE|Building the Pyramids|History|Ancient Egypt|7|9|0.083
mt_B1ATUEVNPz|Egyptian Gods and Goddesses|History|Ancient Egypt|7|9|0.023
mt_bEvMBUv4eG|Egyptian Social Hierarchy|History|Ancient Egypt|7|9|0.022
mt_yNGrY9xJ8Y|Egyptian Tomb Paintings and Artefacts|History|Ancient Egypt|7|9|0.027
mt_cJ8CeyRKKs|Mummification Step by Step|History|Ancient Egypt|7|9|0.016
mt_V_kAitNbLN|Scribes and the Rosetta Stone|History|Ancient Egypt|7|9|0.023
mt_lSFwVU7V9g|Upper and Lower Egypt|History|Ancient Egypt|7|9|0.037
mt_JdAnBKIDnw|Ancient Egypt's Lasting Legacy|History|Ancient Egypt|9|11|0.142
mt_HZyUwycFvf|Cleopatra and the End of Egypt|History|Ancient Egypt|9|11|0.129
mt__qlBYNP62H|Egyptian Art and Architecture|History|Ancient Egypt|9|11|0.094
mt_C3eNLQJlgt|Egyptian Timelines and Maps|History|Ancient Egypt|9|10|0.077
mt_5OxKnrGEMP|Egyptian Trade and Economy|History|Ancient Egypt|9|11|0.045
mt_8qQ2IosZZw|Judgement of the Dead|History|Ancient Egypt|9|11|0.022
mt_PCX1jZZnf9|The Pharaoh as Living God|History|Ancient Egypt|9|11|0.022
mt_B1LdSGMP66|Modern Archaeology and Egyptian Ethics|History|Ancient Egypt|10|12|0.473
mt_PPNDO7BUrY|Egyptian Maths and Engineering|History|Ancient Egypt|11|13|0.079
mt_bhEuF-CCuY|Historical Sources on Ancient Egypt|History|Ancient Egypt|11|13|0.123
mt_NnlnxCx1DO|Egypt and Its Neighbours|History|Ancient Egypt|12|13|0.038
mt_xAG0aMeAIN|Who Really Built the Pyramids|History|Ancient Egypt|12|14|0.316
mt_5qNMVZi3dQ|Fall of Ancient Egyptian Civilisation|History|Ancient Egypt|13|14|0.045
mt_mMMXD4v9Sh|Ancient Greece and Rome on the Map|History|Ancient Greece & Rome|5|7|0.049
mt_19qy2uuaKp|Ancient life vs today|History|Ancient Greece & Rome|5|7|0.029
mt_H1pAi4F_Oh|Greek gods & Mount Olympus|History|Ancient Greece & Rome|5|7|0.031
mt_PhIZNl2230|Greek Myths and Heroes|History|Ancient Greece & Rome|5|7|0.012
mt_VjxyJLtIbT|Roman soldiers & builders|History|Ancient Greece & Rome|5|7|0.033
mt_zh_RyesCgZ|Romulus & Remus|History|Ancient Greece & Rome|5|7|0.033
mt_bKV2JYNwf7|The first Olympics|History|Ancient Greece & Rome|5|7|0.011
mt_8ad4U6msea|Athenian Democracy|History|Ancient Greece & Rome|7|9|0.026
mt_CSGqz245rV|Athens Versus Sparta|History|Ancient Greece & Rome|7|9|0.029
mt_e1Yr6rhRNW|Boudicca's Revolt Against Rome|History|Ancient Greece & Rome|7|9|0.007
mt_6nqVnVdexe|Daily Life in a Roman Town|History|Ancient Greece & Rome|7|9|0.03
mt_VP9yZJ1xeP|Gladiators & Pompeii|History|Ancient Greece & Rome|7|9|0.015
mt_W_CNRTBgYR|Gods & the Parthenon|History|Ancient Greece & Rome|7|9|0.029
mt_FDKd7I79JZ|Greek Gods with Roman Names|History|Ancient Greece & Rome|7|9|0.022
mt_f4O__f3OU4|Greek theatre|History|Ancient Greece & Rome|7|9|0.016
mt_14F_x1Xwwp|Marathon and Thermopylae|History|Ancient Greece & Rome|7|9|0.012
mt_MlD0gwLSw9|Roman Army and Conquest of Britain|History|Ancient Greece & Rome|7|9|0.033
mt_XMz_ohNjYO|Alexander the Great's Empire|History|Ancient Greece & Rome|9|11|0.015
mt_N1744276Zu|Evidence for Greek and Roman Life|History|Ancient Greece & Rome|9|11|0.104
mt_H4bLNkDrGJ|Fall of the Western Roman Empire|History|Ancient Greece & Rome|9|11|0.015
mt_lzCcQzPJZi|Greek and Roman Architecture|History|Ancient Greece & Rome|9|11|0.025
mt_Nj32xtOhno|Greek and Roman Legacy Today|History|Ancient Greece & Rome|9|11|0.153
mt_cUMUYkDqZp|Greek Philosophers and Medicine|History|Ancient Greece & Rome|9|11|0.014
mt_uzk7qs4KxE|Roman Law, Latin, and Christianity|History|Ancient Greece & Rome|9|11|0.03
mt_vFYFvgrPgD|Roman Republic and Empire|History|Ancient Greece & Rome|9|11|0.027
mt_c-F__Qe23X|Hidden Voices of Greece and Rome|History|Ancient Greece & Rome|11|13|0.109
mt_EHiM4_qg1R|Inclusion and Exclusion in Athens|History|Ancient Greece & Rome|11|13|0.015
mt_aXNlkbAeIk|Troy: Myth or History?|History|Ancient Greece & Rome|11|13|0.103
mt__o3TCmfomv|Fall of the Roman Republic|History|Ancient Greece & Rome|12|14|0.108
mt_2GDBmKCJxs|Different Accounts of the Same Event|History|Historical Thinking|6|8|0.04
mt_9REmUc8r4D|Evidence from the Past|History|Historical Thinking|6|7|0.049
mt_VXcua6-txq|Vocabulary: historical thinking|History|Historical Thinking|6|10|0.047
mt_wWlZoLQBR6|Checking Sources Against Each Other|History|Historical Thinking|8|10|0.109
mt_TTzJTF-OkG|Questioning Historical Sources|History|Historical Thinking|8|10|0.09
mt_IlyE-Sm8k5|Understanding People in Their Own Time|History|Historical Thinking|8|10|0.033
mt_Lu4H4mbsqO|Evidence Versus Interpretation|History|Historical Thinking|10|11|0.116
mt_2DBPJ38iWl|Kings & Queens|History|Medieval Times|5|7|0.025
mt_M_xcaRcvSo|Knights & Armour|History|Medieval Times|5|7|0.025
mt_R1xLS1c2Pg|Medieval Clothing|History|Medieval Times|5|7|0.003
mt_2NKzPeLzIm|Medieval Food & Feasts|History|Medieval Times|5|7|0.003
mt_0FYFiLTqx4|Robin Hood & King Arthur|History|Medieval Times|5|7|0.004
mt_X5fdB4haHf|The Vikings|History|Medieval Times|5|7|0.023
mt_PThM5P7Umd|Village Life|History|Medieval Times|5|7|0.027
mt_oN7fI4d_kU|What Is a Castle?|History|Medieval Times|5|7|0.031
mt_26OJ9MetR9|Anglo-Saxon Britain|History|Medieval Times|7|9|0.026
mt_OiDHqtLoln|Battle of Hastings and 1066|History|Medieval Times|7|9|0.042
mt_doVAdMqfJg|Castle Design Through the Ages|History|Medieval Times|7|9|0.03
mt_bjlY5TE1y-|Medieval Pyramid of Power|History|Medieval Times|7|9|0.04
mt_CqzsM0BDFP|Siege Warfare|History|Medieval Times|7|9|0.026
mt_8oAzr0WxRb|The Black Death|History|Medieval Times|7|9|0.026
mt_Zy-CKUkq34|The Crusades|History|Medieval Times|7|9|0.033
mt_LuwHnQItF_|The Medieval Church|History|Medieval Times|7|9|0.037
mt_6XnezHOcM3|Vikings vs Anglo-Saxons|History|Medieval Times|7|9|0.026
mt_pitjUcaAdy|Art & Architecture|History|Medieval Times|9|11|0.051
mt_3tQXH9GwIa|Crime & Punishment|History|Medieval Times|9|11|0.027
mt_8ShghTx0jd|Magna Carta and Limiting Royal Power|History|Medieval Times|9|11|0.036
mt_Ik-WC2ARPf|Medieval Legacy in Modern Life|History|Medieval Times|9|11|0.185
mt_eosO26KE-Z|Medieval Worlds Beyond Europe|History|Medieval Times|9|11|0.179
mt_rf23aL6KwH|Printing Press & Renaissance|History|Medieval Times|9|11|0.053
mt_UMOjbmLcbM|Towns & Trade|History|Medieval Times|9|11|0.033
mt_uuB3owTqNY|Women in the Middle Ages|History|Medieval Times|9|11|0.027
mt_mvXufozy2s|Asking for Help|Learning to Learn|Learning to Learn|5|6|0.312
mt_8dstvf-KKb|Checking Your Own Work|Learning to Learn|Learning to Learn|5|6|0.146
mt_S4G6GLKr1-|Persisting When It's Hard|Learning to Learn|Learning to Learn|5|6|0.25
mt_klyw-tdlhP|Feeling of not understanding|Learning to Learn|Learning to Learn|6|7|0.312
mt_QR3vxbN1o4|Planning a Task|Learning to Learn|Learning to Learn|6|7|0.109
mt_LE7nFEwS12|Thinking Before Starting|Learning to Learn|Learning to Learn|6|7|0.202
mt_32B7xjUPwF|Connecting New & Old Ideas|Learning to Learn|Learning to Learn|7|8|0.13
mt_wvcFlwOrDl|Spotting Patterns|Learning to Learn|Learning to Learn|7|8|0.088
mt_6eTZUwKQZr|Teaching It Back|Learning to Learn|Learning to Learn|7|8|0.161
mt_95zxYqpP7m|Trying a New Approach|Learning to Learn|Learning to Learn|7|8|0.1
mt_hbe_kdE_7C|Describing Rules & Patterns|Learning to Learn|Learning to Learn|8|9|0.029
mt_TDUpy57QVM|Learning from Mistakes|Learning to Learn|Learning to Learn|8|9|0.098
mt_99G6Msdzw-|Transferring Skills|Learning to Learn|Learning to Learn|8|9|0.01
mt_Y6P9y1Rz-u|Understanding Why|Learning to Learn|Learning to Learn|8|9|0.124
mt_q7zxOloj_L|Choosing a Strategy|Learning to Learn|Learning to Learn|9|10|0.104
mt_v5yDTWEiyQ|Reflecting After Learning|Learning to Learn|Learning to Learn|9|10|0.064
mt_2uHYdoxD0H|Finding Knowledge Gaps|Learning to Learn|Learning to Learn|10|11|0.085
mt_jIszRCO2ij|Setting Learning Goals|Learning to Learn|Learning to Learn|10|11|0.083
mt_SbEaQnMQoD|Buyers & Sellers|Life Skills|Entrepreneurship|5|7|0.023
mt_RgQxPddV8v|Goods & Services|Life Skills|Entrepreneurship|5|7|0.022
mt_CrGnpVjnk8|Making Something to Sell|Life Skills|Entrepreneurship|5|7|0.025
mt_vpMDMbx4pc|Who Is a Customer?|Life Skills|Entrepreneurship|5|7|0.025
mt_cq711F7ruL|Being a Good Seller|Life Skills|Entrepreneurship|7|9|0.011
mt_9gpUHWVKMR|Costs & Revenue|Life Skills|Entrepreneurship|7|9|0.037
mt_RTwmvr9R7V|Having a Business Idea|Life Skills|Entrepreneurship|7|9|0.023
mt_dknMcCqvoY|Learning from Failure|Life Skills|Entrepreneurship|7|9|0.026
mt_phpn6KhCAv|Making a Simple Plan|Life Skills|Entrepreneurship|7|9|0.034
mt_M2Gou3O6qT|Marketing Basics|Life Skills|Entrepreneurship|7|9|0.011
mt_pOstrrS763|Teamwork in Business|Life Skills|Entrepreneurship|7|9|0.026
mt_b0sXYFblDL|Ethics in Business|Life Skills|Entrepreneurship|9|11|0.045
mt_bAYy0ytbfC|Pitching an Idea|Life Skills|Entrepreneurship|9|11|0.026
mt_rxJ2O_9Lkr|Real Entrepreneurs|Life Skills|Entrepreneurship|9|11|0.026
mt_7SsduPB2tP|Scaling Up|Life Skills|Entrepreneurship|9|11|0.04
mt_QepALf3bin|Social Enterprise|Life Skills|Entrepreneurship|9|11|0.012
mt_tqgZH11cP5|Supply Chains|Life Skills|Entrepreneurship|9|11|0.042
mt_RNRymbz5SO|Buying Things|Life Skills|Money & Finance|5|7|0.04
mt_FIkqA0qhnj|Coins & Notes|Life Skills|Money & Finance|5|7|0.042
mt_asRwlPZXC3|Jobs People Do|Life Skills|Money & Finance|5|7|0.012
mt_FNSeo9_T2Z|Looking After Money|Life Skills|Money & Finance|5|7|0.021
mt__ab4knIaSL|Needs & Wants|Life Skills|Money & Finance|5|7|0.036
mt_zrCyqhngYm|Saving Money|Life Skills|Money & Finance|5|7|0.021
mt_SsS7GptD_o|What Money Is|Life Skills|Money & Finance|5|7|0.052
mt_My0OL6fhGL|Advertising & Spending|Life Skills|Money & Finance|7|9|0.021
mt_uSUqTjOl8m|Banks & Saving|Life Skills|Money & Finance|7|9|0.019
mt_Qzbh-_v0Gq|Budgeting Pocket Money|Life Skills|Money & Finance|7|9|0.03
mt_uP9faJlnRq|Earning Money|Life Skills|Money & Finance|7|9|0.004
mt_HPf-dVtA3p|Fair Trade & Ethics|Life Skills|Money & Finance|7|9|0.018
mt_aWOK1npO5s|Making Change|Life Skills|Money & Finance|7|9|0.025
mt_K8_RYIvrTV|Ways to Pay|Life Skills|Money & Finance|7|9|0.016
mt_bAy4dmP1-A|Borrowing & Debt|Life Skills|Money & Finance|9|11|0.019
mt_r1hw-KenpK|Financial Planning|Life Skills|Money & Finance|9|11|0.021
mt_0Rx1ISxXFE|Global Trade|Life Skills|Money & Finance|9|11|0.022
mt_udgPy5oAvR|How the Economy Works|Life Skills|Money & Finance|9|11|0.022
mt_W5euSyU2sO|Scams & Online Safety|Life Skills|Money & Finance|9|11|0.03
mt_cSz7XTxVAx|Taxes & Public Services|Life Skills|Money & Finance|9|11|0.019
mt_yJmvUCCym7|Addition and subtraction word problems|Mathematics|Addition & Subtraction|4|6|0.086
mt_OvyoRo47K-|Addition as combining or putting together two|Mathematics|Addition & Subtraction|4|6|0.544
mt_e8CZ7E5qW7|Number bonds to 9|Mathematics|Addition & Subtraction|4|6|0.261
mt_7XcCG43ZZW|Numbers up to 10 into pairs|Mathematics|Addition & Subtraction|4|6|0.261
mt_PgsHGYJMH-|Representing Addition and Subtraction|Mathematics|Addition & Subtraction|4|6|0.086
mt_zuKAX6lcYR|Subtraction as taking away or separating|Mathematics|Addition & Subtraction|4|6|0.651
mt_mr_Vk7FGzK|Adding and subtracting|Mathematics|Addition & Subtraction|5|6|0.077
mt_VAWV_l7J0D|Early Word Problems|Mathematics|Addition & Subtraction|5|7|0.077
mt_ghF3Vv6taM|Fluent adding and subtracting within 5|Mathematics|Addition & Subtraction|5|6|0.175
mt_s2mfRBoTal|Number bonds|Mathematics|Addition & Subtraction|5|6|0.078
mt_8RmpkDxT9L|Reading +, −, and = symbols|Mathematics|Addition & Subtraction|5|6|0.378
mt_I5j1ZWo2cn|Adding and subtracting tens mentally|Mathematics|Addition & Subtraction|6|7|0.016
mt_Zx1xZM-RbX|Adding Three Small Numbers|Mathematics|Addition & Subtraction|6|7|0.011
mt_UQnAFPs83F|Adding two two-digit numbers|Mathematics|Addition & Subtraction|6|7|0.027
mt_glPPG-kTQY|Adding within 100|Mathematics|Addition & Subtraction|6|7|0.163
mt_PpWSHA-0kv|Addition and subtraction strategies|Mathematics|Addition & Subtraction|6|7|0.007
mt_m1W6nTQJ2b|Addition and subtraction within 20|Mathematics|Addition & Subtraction|6|7|0.168
mt_QCgbiVrwnp|Addition in any order|Mathematics|Addition & Subtraction|6|7|0.156
mt_ezc2m_0dzN|Finding a missing number in addition|Mathematics|Addition & Subtraction|6|7|0.088
mt__we2TDqnJx|Fluent adding and subtracting within 10|Mathematics|Addition & Subtraction|6|7|0.168
mt_3e_PQxwC12|Fluent addition and subtraction|Mathematics|Addition & Subtraction|6|7|0.021
mt_T76hKqXf0z|Grouping numbers to add|Mathematics|Addition & Subtraction|6|7|0.008
mt_ehGS_uVSJv|Inverse: addition undoes subtraction|Mathematics|Addition & Subtraction|6|7|0.088
mt_AKAtWEwpcj|Mental addition and subtraction (age 6+)|Mathematics|Addition & Subtraction|6|7|0.023
mt_wzAZ8qFDc4|Mental and written addition and subtraction|Mathematics|Addition & Subtraction|6|7|0.031
mt_HJTuIGHvcR|Subtracting multiples of 10|Mathematics|Addition & Subtraction|6|7|0.015
mt_3JgrHY221M|Unknown in Addition & Subtraction|Mathematics|Addition & Subtraction|6|7|0.022
mt_oIzycTBeE4|What the equals sign means|Mathematics|Addition & Subtraction|6|7|0.167
mt_SrrsLiJkr3|Adding and subtracting (age 7+)|Mathematics|Addition & Subtraction|7|8|0.126
mt_TiQbi027PE|Adding numbers|Mathematics|Addition & Subtraction|7|8|0.029
mt_zxST3MarI9|Addition and subtraction strategies (age 7+)|Mathematics|Addition & Subtraction|7|8|0.053
mt_ewmuMMPAzP|Addition and subtraction within 1000|Mathematics|Addition & Subtraction|7|8|0.142
mt_QaYfeVL-0C|Estimating by rounding|Mathematics|Addition & Subtraction|7|9|0.096
mt_cChv2j_-Da|Fluent adding and subtracting within 100|Mathematics|Addition & Subtraction|7|8|0.163
mt__t4afSyZRm|Fluent adding and subtracting within 20|Mathematics|Addition & Subtraction|7|8|0.153
mt_oDU_8zMZjp|Mental addition and subtraction (age 7+)|Mathematics|Addition & Subtraction|7|8|0.033
mt_xPqczp7zPX|Mentally adding hundreds to 3-digit numbers|Mathematics|Addition & Subtraction|7|8|0.018
mt_aHQ9kNt3is|Mentally adding tens to 3-digit numbers|Mathematics|Addition & Subtraction|7|8|0.018
mt_XuHmIn2xje|Missing number problems (age 7+)|Mathematics|Addition & Subtraction|7|8|0.09
mt_19j_5AuuQI|Numbers on a number line|Mathematics|Addition & Subtraction|7|8|0.036
mt_yTWxkzzoOZ|Two-Step Word Problems|Mathematics|Addition & Subtraction|7|8|0.086
mt_mpS-JK_p_m|Adding and subtracting (age 8+)|Mathematics|Addition & Subtraction|8|9|0.045
mt_HFRYjTb-Z5|Fluent adding and subtracting within 1000|Mathematics|Addition & Subtraction|8|9|0.031
mt_CDa5AVakLE|Two-step addition and subtraction problems|Mathematics|Addition & Subtraction|8|9|0.045
mt_anAe11HAEH|Two-Step Equations|Mathematics|Addition & Subtraction|8|9|0.053
mt_-F_Lv_apzH|Adding and subtracting (age 9+)|Mathematics|Addition & Subtraction|9|10|0.051
mt_G3sVFQNCme|Checking Answers by Rounding|Mathematics|Addition & Subtraction|9|10|0.048
mt_Yw1_4Nfsql|Fluent addition and subtraction (age 9+)|Mathematics|Addition & Subtraction|9|10|0.044
mt_MWXPiaTnEu|Mental addition and subtraction (age 9+)|Mathematics|Addition & Subtraction|9|10|0.036
mt_M1tnXqmYbn|Adding and subtracting (age 10+)|Mathematics|Addition & Subtraction|10|11|0.108
mt_JH_6RpNWjr|Addition and subtraction strategies (age 10+)|Mathematics|Addition & Subtraction|10|11|0.085
mt_9QzSnn8m80|Positive and Negative Numbers|Mathematics|Addition & Subtraction|11|13|0.051
mt_YFS7JFk64p|Equations with Two Unknowns|Mathematics|Algebra|10|11|0.083
mt_hBZwbst0ow|Linear number sequences|Mathematics|Algebra|10|11|0.049
mt_fxPtngwUfz|Number Pattern Relationships|Mathematics|Algebra|10|11|0.09
mt_gu0NPDvlhY|Systematic Listing|Mathematics|Algebra|10|11|0.059
mt_Jvg8X0N5u0|Using Simple Formulae|Mathematics|Algebra|10|11|0.126
mt_i9rJbuFO3p|Writing Algebraic Equations|Mathematics|Algebra|10|11|0.124
mt_KwdjWEmMNo|Algebraic Notation|Mathematics|Algebra|11|12|0.123
mt_z5iwdZyeDr|Algebraic Transformations|Mathematics|Algebra|11|13|0.115
mt_nNNVrLqPW3|Collecting Like Terms|Mathematics|Algebra|11|12|0.119
mt_hVpGOEz2kG|Coordinates (age 11+)|Mathematics|Algebra|11|12|0.134
mt_FX4a2Q8XXN|Expanding Single Brackets|Mathematics|Algebra|11|13|0.119
mt_g_fkAqmz72|Expressions & Equations Vocabulary|Mathematics|Algebra|11|12|0.119
mt_yXO7lQ9Yn7|Generating Sequences|Mathematics|Algebra|11|14|0.098
mt_i2F1nWxJjv|Numbers on a number line|Mathematics|Algebra|11|14|0.156
mt_QhFEDyIwSO|Solving Linear Equations|Mathematics|Algebra|11|14|0.122
mt_vHzVa3SURC|Substituting into Formulae|Mathematics|Algebra|11|12|0.115
mt_uESbzWCZIq|Factorising Expressions|Mathematics|Algebra|12|13|0.089
mt_WBdHkc2HTf|Linear Function Graphs|Mathematics|Algebra|12|14|0.207
mt_HRKzwEQJgO|Nth-Term Rules|Mathematics|Algebra|12|14|0.108
mt_-3udyo6VyB|Plotting Linear Graphs|Mathematics|Algebra|12|14|0.196
mt_3qrCtdoVAU|Simple formulae|Mathematics|Algebra|12|14|0.111
mt_Yw27nweoTj|Estimating answers (age 13+)|Mathematics|Algebra|13|14|0.194
mt_KhS7K1Mgrw|Expanding Double Brackets|Mathematics|Algebra|13|14|0.089
mt_GZuoYaDdWd|Quadratic Graphs|Mathematics|Algebra|13|14|0.194
mt_mqgu72aCMz|Simultaneous Equations|Mathematics|Algebra|13|14|0.194
mt__h7hvT4tEb|Comparing groups: more or fewer|Mathematics|Counting & Cardinality|4|6|0.287
mt_dmNvjroCPT|How Many in Total?|Mathematics|Counting & Cardinality|4|6|0.97
mt_sYpKWbq5ra|One More Each Time|Mathematics|Counting & Cardinality|4|6|0.026
mt_WcfaSfVT33|One-to-one counting|Mathematics|Counting & Cardinality|4|6|1
mt_pAcaehday5|Representing numbers with objects|Mathematics|Counting & Cardinality|4|6|0.048
mt_nvdpxAJTBG|Counting in 2s|Mathematics|Counting & Cardinality|5|7|0.384
mt_yqAL6O5i_v|Counting objects to 20|Mathematics|Counting & Cardinality|5|6|0.295
mt_M5PPDJStGm|Rote counting to 100|Mathematics|Counting & Cardinality|5|6|0.462
mt__YRJ23GuIK|Two written numerals between 1 and 10|Mathematics|Counting & Cardinality|5|6|0.133
mt_aHAM29nidj|Counting forwards and backwards|Mathematics|Counting & Cardinality|6|7|0.004
mt_OkSJfrmFb_|Counting forwards and backwards (age 6+)|Mathematics|Counting & Cardinality|6|7|0.014
mt_M2v1A9OEuM|Counting Within 1,000|Mathematics|Counting & Cardinality|7|8|0.06
mt_IzQvs7k_sE|Skip Counting (4s, 8s, 50s, 100s)|Mathematics|Counting & Cardinality|7|8|0.19
mt_7rJM8eWUfw|Counting in 6s|Mathematics|Counting & Cardinality|8|9|0.172
mt_xppl18avyY|Sorting into categories|Mathematics|Data & Statistics|5|6|0.172
mt_c29FaCTNsx|Pictograms and tally charts|Mathematics|Data & Statistics|6|8|0.148
mt_u5HkSxZECM|Pictograms and tally charts (age 6+)|Mathematics|Data & Statistics|6|9|0.156
mt_ylXdiVRAYv|Sorting Data into Categories|Mathematics|Data & Statistics|6|8|0.163
mt_1VSfm9yiLn|Sorting into categories (age 6+)|Mathematics|Data & Statistics|6|8|0.03
mt_VhBH8wrFC6|Picture & Bar Graphs|Mathematics|Data & Statistics|7|8|0.115
mt_ChjMU2GDJa|Bar graphs|Mathematics|Data & Statistics|8|9|0.052
mt_r8XnXwRA6g|Representing numbers with objects (age 8+)|Mathematics|Data & Statistics|8|9|0.116
mt_H6LlpWgEYS|Reading and Comparing Bar Graphs|Mathematics|Data & Statistics|9|10|0.025
mt_Cqm8iy48UI|Reading tables|Mathematics|Data & Statistics|9|10|0.071
mt_fmm-P17Vka|Statistical Analysis Vocabulary|Mathematics|Data & Statistics|9|11|0.007
mt_Cg8VPguS_V|Calculating the Mean|Mathematics|Data & Statistics|10|11|0.138
mt_bESTSBB0wK|Line graphs (age 10+)|Mathematics|Data & Statistics|10|11|0.171
mt_IHipFGTFEY|Understanding fractions|Mathematics|Data & Statistics|10|11|0.103
mt_XSXnTQoQ4l|Comparing measurements|Mathematics|Data & Statistics|11|13|0.22
mt_eKJG-0eC6D|Pictograms and tally charts (age 11+)|Mathematics|Data & Statistics|11|13|0.2
mt_BdAeZJUOir|Scatter Graphs|Mathematics|Data & Statistics|13|14|0.285
mt_8atyuvPUZc|Scatter Graphs & Correlation|Mathematics|Data & Statistics|13|14|0.285
mt_g3W0mdADVu|Finding halves and quarters (age 5+)|Mathematics|Fractions|5|6|0.26
mt_-hTTat0mBR|What Is a Half?|Mathematics|Fractions|5|6|0.347
mt_hyvHv2BCwb|Decomposing a shape into more equal shares|Mathematics|Fractions|6|7|0.216
mt_vKcxX6iNOA|Fraction Notation|Mathematics|Fractions|6|9|0.249
mt_cFltwUQi-d|Fractions of amounts|Mathematics|Fractions|6|7|0.257
mt_xACS3rWWDp|Halves & Quarters of Shapes|Mathematics|Fractions|6|7|0.216
mt_MyGblah2yY|Understanding fractions|Mathematics|Fractions|6|7|0.196
mt_IfEgu0X449|Comparing fractions|Mathematics|Fractions|7|8|0.063
mt_SsLWS_APM7|Comparing fractions (age 7+)|Mathematics|Fractions|7|8|0.025
mt_FbDKeLfBCo|Equivalent fractions|Mathematics|Fractions|7|8|0.201
mt_Kr3IyA6m-O|Fractions on a number line|Mathematics|Fractions|7|8|0.227
mt_a1FdAsRKOF|Simple Fraction Sums|Mathematics|Fractions|7|8|0.071
mt_Xp-rj46S2w|Splitting shapes into equal parts (age 7+)|Mathematics|Fractions|7|8|0.208
mt_YzM5goBctT|Tenths|Mathematics|Fractions|7|8|0.242
mt_k2WE0-22-4|Unit fractions|Mathematics|Fractions|7|8|0.04
mt_CBHwluE6Lp|Adding Fractions (Same Denominator)|Mathematics|Fractions|8|9|0.064
mt_HnKbuCliNS|Comparing fractions (age 8+)|Mathematics|Fractions|8|9|0.051
mt_TqDq6jyOmL|Decimal equivalents of tenths and hundredths|Mathematics|Fractions|8|9|0.135
mt_W17Kbwm0-u|Decimal & Percent Notation|Mathematics|Fractions|8|11|0.119
mt_Fl7b8q9pI1|Decimal place value|Mathematics|Fractions|8|9|0.022
mt_IegHBHERVa|Decimal place value (age 8+)|Mathematics|Fractions|8|9|0.073
mt_wB-GBDkoNr|Decimals and fractions|Mathematics|Fractions|8|9|0.027
mt_kDMKJ5Ztt6|Dividing by 10 and 100|Mathematics|Fractions|8|9|0.067
mt_FP-mjXaq3B|Equivalent fractions (age 8+)|Mathematics|Fractions|8|9|0.204
mt_Ep7TDFuYUa|Equivalent fractions on a number line|Mathematics|Fractions|8|9|0.208
mt_DRlbMok2lT|Fraction-Decimal Equivalents|Mathematics|Fractions|8|9|0.083
mt_idbKDrf9qZ|Fractions as parts of shapes|Mathematics|Fractions|8|9|0.016
mt_3y7xKP9MjU|Fractions of amounts (harder)|Mathematics|Fractions|8|9|0.031
mt_ndGqFPWyen|Fractions of a whole|Mathematics|Fractions|8|9|0.211
mt_AYzE1EAvI0|Fractions of a whole (age 8+)|Mathematics|Fractions|8|9|0.045
mt_NoB20kVa4w|Fractions on a number line (age 8+)|Mathematics|Fractions|8|9|0.198
mt_doX1BhmFgk|Tenths (age 8+)|Mathematics|Fractions|8|9|0.135
mt_70qDTI14td|Adding and subtracting mixed numbers|Mathematics|Fractions|9|10|0.034
mt_-V7EnqU7gG|Adding fractions (different denominators)|Mathematics|Fractions|9|10|0.07
mt_ZLqYE7la4Z|Addition and subtraction word problems|Mathematics|Fractions|9|10|0.034
mt_933BohS9BH|Comparing Decimals|Mathematics|Fractions|9|10|0.098
mt_SXbZ3bC9z7|Comparing fractions (age 9+)|Mathematics|Fractions|9|10|0.064
mt_NaqEP8xDhZ|Converting tenths to hundredths|Mathematics|Fractions|9|10|0.14
mt_Ii1hV4V5ql|Decimal place value (age 9+)|Mathematics|Fractions|9|10|0.022
mt_Vi4Vo5xs_g|Decimals for Tenths & Hundredths|Mathematics|Fractions|9|10|0.142
mt_sA2OvTiech|Decimals to three places|Mathematics|Fractions|9|10|0.051
mt_ebPelt-qAl|Equivalent fractions (age 9+)|Mathematics|Fractions|9|10|0.202
mt_VgOePicFYK|Fraction Addition Concepts|Mathematics|Fractions|9|10|0.06
mt_HJA2Oz-Zh1|Fractions of a whole (age 9+)|Mathematics|Fractions|9|10|0.021
mt_o_p-3tCxiM|Mixed numbers and improper fractions|Mathematics|Fractions|9|10|0.047
mt_TgHxujL81r|Multiplying fractions|Mathematics|Fractions|9|10|0.093
mt_4ubP_RMg9o|Percentage and decimal equivalents|Mathematics|Fractions|9|10|0.09
mt_kdWoAel3Zl|Tenths (age 9+)|Mathematics|Fractions|9|10|0.119
mt_09sySPqM9Z|Understanding fractions (age 9+)|Mathematics|Fractions|9|10|0.108
mt_ZM9mhHsyYZ|Understanding Percentages|Mathematics|Fractions|9|10|0.09
mt_14T5yPXUq_|Adding Fractions (Unlike Denominators)|Mathematics|Fractions|10|11|0.089
mt_gx6KQK5-Kx|Area with Fractions|Mathematics|Fractions|10|11|0.108
mt_PL9VkDwXfh|Comparing fractions (age 10+)|Mathematics|Fractions|10|11|0.06
mt_4K1dr204Hi|Decimals and fractions (age 10+)|Mathematics|Fractions|10|11|0.146
mt_1PAWhRhpdg|Dividing by Fractions|Mathematics|Fractions|10|11|0.107
mt_ifPDOYvUqm|Dividing fractions (unit fractions)|Mathematics|Fractions|10|11|0.109
mt_rCMdwG-YOE|Dividing unit fractions and whole numbers|Mathematics|Fractions|10|11|0.108
mt_4Km38F4L-6|Fractions of a whole (age 10+)|Mathematics|Fractions|10|11|0.131
mt_e7filQgayF|Fraction Word Problems|Mathematics|Fractions|10|11|0.07
mt_VKW8lOcFaw|Multiplication as scaling|Mathematics|Fractions|10|11|0.108
mt_AabJisinfi|Multiplying fractions (age 10+)|Mathematics|Fractions|10|11|0.101
mt_lvaSGHwvQ5|Real-world fraction multiplication|Mathematics|Fractions|10|11|0.107
mt_b7T-CjOYUR|Simplifying Fractions|Mathematics|Fractions|10|11|0.112
mt_SBkTGjiZjZ|Decimals and fractions (age 11+)|Mathematics|Fractions|11|13|0.109
mt_9Y96vxG_LH|Dividing fractions|Mathematics|Fractions|11|12|0.105
mt_gNUE4B3vuk|Mixed & Improper Fractions|Mathematics|Fractions|11|13|0.115
mt_J339bO7qLe|Multiplying fractions (age 11+)|Mathematics|Fractions|11|12|0.131
mt_KJeEeTutJI|2-D shapes|Mathematics|Geometry|4|6|0.192
mt_Qcp2d_kuta|3-D shapes|Mathematics|Geometry|4|6|0.234
mt_qeZYF6HZ4o|Positional Language|Mathematics|Geometry|4|6|0.152
mt_yGv8doDAmp|3-D shapes (age 5+)|Mathematics|Geometry|5|6|0.19
mt_2VR963szuk|Building & Drawing Shapes|Mathematics|Geometry|5|6|0.005
mt_XjwUlmxdCT|Combining Simple Shapes|Mathematics|Geometry|5|6|0.005
mt_mnEVZNkX3p|Flat vs Solid Shapes|Mathematics|Geometry|5|6|0.004
mt_Y9XKzLrUAZ|Turns & Directions|Mathematics|Geometry|5|6|0.155
mt_UooUHC_V7U|2-D faces on 3-D shapes|Mathematics|Geometry|6|7|0.004
mt_sBcRdUfAzV|2-D shapes (age 6+)|Mathematics|Geometry|6|7|0.183
mt_bfhng6mOuy|Angles in triangles (age 6+)|Mathematics|Geometry|6|7|0.183
mt_QNxFnxikCN|Building with 3-D Shapes|Mathematics|Geometry|6|7|0.005
mt_MqqR7VUoz1|Composing Shapes|Mathematics|Geometry|6|7|0.005
mt_Mnodea7mG_|Edges, vertices, and faces|Mathematics|Geometry|6|7|0.031
mt_WXW0hjNhph|Patterns & Sequences|Mathematics|Geometry|6|7|0.004
mt_TdV9YGJEoY|Position, direction, and movement|Mathematics|Geometry|6|7|0.155
mt_fEuoBYw6bU|Sorting 2-D and 3-D shapes|Mathematics|Geometry|6|7|0.01
mt_vJUa62bxeR|2-D shapes (age 7+)|Mathematics|Geometry|7|8|0.033
mt_zuOGOGFAKb|Angles in triangles (age 7+)|Mathematics|Geometry|7|8|0.077
mt_u23IGDxOpk|Parallel and perpendicular lines|Mathematics|Geometry|7|8|0.082
mt_MFfYcnv6Tv|Right Angles & Turns|Mathematics|Geometry|7|8|0.142
mt_8OAGVdeTJ_|Understanding angles|Mathematics|Geometry|7|8|0.141
mt_hRZyKvz1KN|2-D shapes (age 8+)|Mathematics|Geometry|8|10|0.015
mt_i5_HnoFOYw|Coordinates (age 8+)|Mathematics|Geometry|8|9|0.052
mt_Uq5vYqboCR|Describing Movements|Mathematics|Geometry|8|9|0.019
mt_jBQS-CicNn|First Quadrant Coordinates|Mathematics|Geometry|8|9|0.06
mt_hR2Y7NhMSY|Lines of symmetry|Mathematics|Geometry|8|9|0.015
mt_vnJEztczji|Nets of 3-D Shapes|Mathematics|Geometry|8|11|0.027
mt_SH7QgFl8-v|Transformations on a grid|Mathematics|Geometry|8|12|0.031
mt_h0CVtqI2xo|Types of angles|Mathematics|Geometry|8|9|0.138
mt_e4V6hvcuEJ|Types of angles (age 8+)|Mathematics|Geometry|8|12|0.123
mt_Xt1cRqaBOW|Understanding angles (age 8+)|Mathematics|Geometry|8|9|0.077
mt_wUSbRt3-qw|3-D shapes (age 9+)|Mathematics|Geometry|9|10|0.033
mt_oqziWKry-L|Angle Sum Rules|Mathematics|Geometry|9|10|0.073
mt_r8c43QB6wx|Classifying shapes by line properties|Mathematics|Geometry|9|10|0.053
mt_qUGMyMYn9m|Degrees and turns|Mathematics|Geometry|9|10|0.109
mt_YUJ5pwalqL|Estimating Angles|Mathematics|Geometry|9|10|0.059
mt_QysgF57dxh|Lines, Rays & Angles|Mathematics|Geometry|9|10|0.079
mt_4MFUAsbx_6|Measuring angles|Mathematics|Geometry|9|10|0.083
mt_89riIKwGYp|Measuring angles (age 9+)|Mathematics|Geometry|9|10|0.06
mt_8H2kO4k2B9|Regular and irregular polygons|Mathematics|Geometry|9|10|0.062
mt_efOeaGFyGM|Transformations on a Grid|Mathematics|Geometry|9|10|0.033
mt_KFKUR_gBg_|Understanding angles (age 9+)|Mathematics|Geometry|9|10|0.053
mt_3S10OOGPqu|What Is an Angle?|Mathematics|Geometry|9|10|0.109
mt_hdrMoiTgqu|2-D shapes (age 10+)|Mathematics|Geometry|10|11|0.037
mt_REwgr0d_ss|3-D shapes (age 10+)|Mathematics|Geometry|10|11|0.014
mt_cdMlC7EpTJ|Angles in triangles (age 10+)|Mathematics|Geometry|10|11|0.045
mt_liIW336odh|Classifying shapes by properties|Mathematics|Geometry|10|11|0.059
mt_R4AY0LKxfl|Coordinates (age 10+)|Mathematics|Geometry|10|11|0.079
mt_oDlduFnemk|Numbers on a number line|Mathematics|Geometry|10|11|0.055
mt_xq3YHZ2zeR|Parts of a circle|Mathematics|Geometry|10|11|0.003
mt_snlqRCiA1R|Plotting points in the first quadrant|Mathematics|Geometry|10|11|0.055
mt_lxaM6iVpdr|Translating and reflecting shapes|Mathematics|Geometry|10|11|0.064
mt_QDTO3GAgcq|Understanding angles (age 10+)|Mathematics|Geometry|10|11|0.037
mt_nRksLqt-iR|3-D shapes (age 11+)|Mathematics|Geometry|11|13|0.014
mt_tAJH5BrpOx|Angles in triangles (age 11+)|Mathematics|Geometry|11|14|0.163
mt_J03RFlVdas|Angle sums in triangles and polygons|Mathematics|Geometry|11|14|0.127
mt_K0Y15w48SY|Coordinate Transformations|Mathematics|Geometry|11|14|0.122
mt_Jf8xcX4UTq|Measuring angles (age 11+)|Mathematics|Geometry|11|13|0.037
mt_DNYQLahbfa|Properties of triangles and quadrilaterals|Mathematics|Geometry|11|13|0.038
mt_WtIFJSCQIT|Types of angles (age 11+)|Mathematics|Geometry|11|13|0.04
mt_tedML_iu4Y|Understanding angles (age 11+)|Mathematics|Geometry|11|13|0.037
mt_167X6Ax8P7|Angles in triangles (age 12+)|Mathematics|Geometry|12|14|0.042
mt_H_pNJ3ZI_S|Angles with parallel lines|Mathematics|Geometry|12|14|0.033
mt_svFa6_mjO_|Circles: Circumference & Area|Mathematics|Geometry|12|14|0.164
mt_y-BuQAfw4B|Coordinates (age 12+)|Mathematics|Geometry|12|14|0.193
mt_ZrsqGVG-Wt|Understanding angles (age 12+)|Mathematics|Geometry|12|14|0.036
mt_KB_Czd7RQH|Trigonometry basics|Mathematics|Geometry|13|15|0.14
mt_1VmTUxBrNd|Types of angles (age 13+)|Mathematics|Geometry|13|14|0.14
mt_lMz9nAs7VO|Early Maths Vocabulary|Mathematics|Mathematical Thinking|5|6|0.015
mt_RFeVlw0QvX|Finding efficient methods|Mathematics|Mathematical Thinking|5|6|0.014
mt_20WfHhnL39|Hands-On Problem Solving|Mathematics|Mathematical Thinking|5|6|0.011
mt_WkKkb7W9Qd|Making Sense of Problems|Mathematics|Mathematical Thinking|5|6|0.071
mt_IM1G_7QzTa|Real-World to Maths Connections|Mathematics|Mathematical Thinking|5|6|0.015
mt_nyK25mNOeR|Showing Your Working|Mathematics|Mathematical Thinking|5|6|0.149
mt_uG2mjHFOlO|Spotting mathematical patterns|Mathematics|Mathematical Thinking|5|6|0.016
mt_fLOkq-HfPB|Using objects to model real problems|Mathematics|Mathematical Thinking|5|6|0.019
mt_f67qGDhyfi|Connecting maths to real life|Mathematics|Mathematical Thinking|6|7|0.042
mt_EBYGhd8X3x|Connecting Representations|Mathematics|Mathematical Thinking|6|7|0.023
mt_kJ5wYzO8qC|Explaining Mathematical Reasoning|Mathematics|Mathematical Thinking|6|7|0.159
mt_fZTn0W_iZR|Generalising Patterns|Mathematics|Mathematical Thinking|6|7|0.033
mt_O_UOTiMvT_|Guided Multi-Step Problem Solving|Mathematics|Mathematical Thinking|6|7|0.079
mt_zMEvtigoM3|Numbers on a number line|Mathematics|Mathematical Thinking|6|7|0.037
mt_TMoHjMhRS2|Precise Maths Communication|Mathematics|Mathematical Thinking|6|7|0.031
mt_DW2D1c0fKx|Shape patterns|Mathematics|Mathematical Thinking|6|7|0.021
mt_mQcWGh02no|Choosing the right strategy|Mathematics|Mathematical Thinking|7|8|0.053
mt_2jbUekyTu4|Extending Table Patterns|Mathematics|Mathematical Thinking|7|8|0.038
mt_pyMD_SIiYO|Justifying mathematical reasoning|Mathematics|Mathematical Thinking|7|8|0.077
mt_RKeheOL9uo|Multi-Step Problem Solving|Mathematics|Mathematical Thinking|7|8|0.104
mt_FAXjFkgG6X|Shape patterns (age 7+)|Mathematics|Mathematical Thinking|7|8|0.049
mt_dXq9VWm31W|Understanding fractions|Mathematics|Mathematical Thinking|7|8|0.057
mt_HY8Yycu_rz|Understanding fractions (age 7+)|Mathematics|Mathematical Thinking|7|8|0.097
mt_iQYPw8bMfN|Working with money|Mathematics|Mathematical Thinking|7|8|0.077
mt_d-WZC2OyMB|Choosing mathematical tools|Mathematics|Mathematical Thinking|8|9|0.094
mt_3VmBdlAeOZ|Fractions on a number line|Mathematics|Mathematical Thinking|8|9|0.083
mt_a3dov8CZkq|Justifying mathematical reasoning (age 8+)|Mathematics|Mathematical Thinking|8|9|0.105
mt_mywsN77hGZ|Mathematical Precision|Mathematics|Mathematical Thinking|8|9|0.119
mt_K3R0yaHVcx|Modelling with multiplication and fractions|Mathematics|Mathematical Thinking|8|9|0.094
mt_SmghasIvbT|Multi-Step Problem Solving|Mathematics|Mathematical Thinking|8|9|0.119
mt_aivrWs6jrS|Times tables (age 8+)|Mathematics|Mathematical Thinking|8|9|0.088
mt__Itf4aQZUj|Using Mathematical Structure|Mathematics|Mathematical Thinking|8|9|0.066
mt_IwEOCN6bL1|Choosing representations strategically|Mathematics|Mathematical Thinking|9|10|0.124
mt_GpltXPoaoc|Complex Multi-Step Problems|Mathematics|Mathematical Thinking|9|10|0.179
mt_hlGKg5M7qJ|Fractions, Decimals & Percentages|Mathematics|Mathematical Thinking|9|10|0.089
mt_CUmjcE7W6c|Fractions on a number line (age 9+)|Mathematics|Mathematical Thinking|9|10|0.115
mt_xfwv0M83mJ|Precise Maths Vocabulary|Mathematics|Mathematical Thinking|9|10|0.137
mt_8xVHooT4aI|Real-World Maths Modelling|Mathematics|Mathematical Thinking|9|10|0.135
mt_jCy07DyBNU|Reasoning with Equivalences|Mathematics|Mathematical Thinking|9|10|0.104
mt_2ESZh70NyS|Understanding fractions (age 9+)|Mathematics|Mathematical Thinking|9|10|0.137
mt_3rTIyJDw7-|Advanced Maths Vocabulary|Mathematics|Mathematical Thinking|10|11|0.187
mt_FieL-vVTI_|Advanced Multi-Step Problems|Mathematics|Mathematical Thinking|10|11|0.213
mt_ZJC7JnnPCu|Choosing Maths Tools|Mathematics|Mathematical Thinking|10|11|0.163
mt_j5YqQnN6xe|Constructing mathematical arguments|Mathematics|Mathematical Thinking|10|11|0.187
mt_iyovKgZC1q|Generalising with repeated reasoning|Mathematics|Mathematical Thinking|10|11|0.146
mt_hImiKNiaNh|Order of operations (age 10+)|Mathematics|Mathematical Thinking|10|11|0.16
mt_yqZiX6vS7D|Real-World Mathematical Modelling|Mathematics|Mathematical Thinking|10|11|0.212
mt_9KmVWCuh5_|Understanding fractions (age 10+)|Mathematics|Mathematical Thinking|10|11|0.213
mt_zkFbMLpu3U|Comparing Capacity|Mathematics|Measurement|4|6|0.226
mt_TcG90kS8nu|Comparing durations|Mathematics|Measurement|4|6|0.07
mt_uhuxX8sg9f|Comparing Lengths & Heights|Mathematics|Measurement|4|6|0.23
mt_NtJYlJdUe9|Measurable Attributes of Objects|Mathematics|Measurement|4|6|0.267
mt_-P1kdZhHbL|Measuring mass and weight (age 4+)|Mathematics|Measurement|4|6|0.226
mt_-vvVxpOHG2|Ordering Events in Time|Mathematics|Measurement|4|6|0.223
mt_4lp_b5Pzik|Capacity and volume|Mathematics|Measurement|5|6|0.226
mt_cPZwlUk8Nd|Coin Values|Mathematics|Measurement|5|6|0.051
mt_bj1YCgNWUx|Days, Weeks, Months & Years|Mathematics|Measurement|5|6|0.223
mt_KaF0SQvaiu|Measuring length and height (age 5+)|Mathematics|Measurement|5|6|0.228
mt_zd0YkB3xNj|Measuring mass and weight|Mathematics|Measurement|5|6|0.226
mt_0XxyaQLRhn|Telling Time: Hours and Half Hours|Mathematics|Measurement|5|6|0.053
mt__N55B7u7HD|Telling time to the minute|Mathematics|Measurement|5|6|0.07
mt_AF2BeFQwfX|Adding money and giving change|Mathematics|Measurement|6|7|0.025
mt_DOe893F6gN|Choosing measurement units|Mathematics|Measurement|6|7|0.231
mt_BFJ-ch_8QU|Comparing and ordering measurements|Mathematics|Measurement|6|7|0.111
mt_skYly2Qm01|Measuring length|Mathematics|Measurement|6|7|0.189
mt_cqSf213hSa|Measuring length (age 6+)|Mathematics|Measurement|6|7|0.19
mt_6J1wmCWf41|Money Addition & Subtraction|Mathematics|Measurement|6|7|0.026
mt_2XDGT5tei1|Number of minutes in an hour|Mathematics|Measurement|6|7|0.06
mt_pbuhUQJjtt|Pounds & Pence Notation|Mathematics|Measurement|6|7|0.023
mt_6XCURuNwPw|Sequence intervals of time|Mathematics|Measurement|6|7|0.037
mt_HNOPGJYiRK|Telling Time: Minutes|Mathematics|Measurement|6|7|0.056
mt_DLcEzmmj2r|Addition and subtraction word problems|Mathematics|Measurement|7|8|0.047
mt_6oxQPNLHNv|Calculating with measurements|Mathematics|Measurement|7|8|0.111
mt_xWg0lI_gG4|Comparing lengths by measuring|Mathematics|Measurement|7|8|0.022
mt_4emC463IyW|Comparing Time Durations|Mathematics|Measurement|7|8|0.057
mt_3XJkeIn6J6|Estimating answers (age 7+)|Mathematics|Measurement|7|8|0.055
mt_OzRZ89GrQW|Estimating Lengths|Mathematics|Measurement|7|8|0.015
mt_6_O6THdEDK|Giving Change|Mathematics|Measurement|7|8|0.019
mt_3tz3Otap5j|Halves and quarters (age 7+)|Mathematics|Measurement|7|8|0.025
mt_e4x3l2JeLI|Measuring length (age 7+)|Mathematics|Measurement|7|8|0.196
mt_wE7-Gs9ENL|Measuring Perimeters|Mathematics|Measurement|7|8|0.064
mt_mayItsxMUu|Measuring & Plotting Lengths|Mathematics|Measurement|7|8|0.044
mt_jHv4BgRK8B|Measuring with different units|Mathematics|Measurement|7|8|0.015
mt_4m8BimI4G5|Telling time to the minute (age 7+)|Mathematics|Measurement|7|8|0.056
mt_EXlmTURK_o|Time Units and Calendar Facts|Mathematics|Measurement|7|8|0.06
mt_WfrE_4r-kY|12-hour and 24-hour time|Mathematics|Measurement|8|9|0.021
mt_y1n0Zwhoca|Area (age 8+)|Mathematics|Measurement|8|9|0.179
mt_AQo4u7O4sM|Area and the distributive property|Mathematics|Measurement|8|9|0.146
mt_Jvvh5P06NV|Area by Tiling|Mathematics|Measurement|8|9|0.172
mt_eMtV6tBSJm|Area of compound shapes|Mathematics|Measurement|8|9|0.022
mt_d8al9JcajP|Converting measurement units|Mathematics|Measurement|8|9|0.083
mt_mFJ-2ZF6Tk|Estimating and comparing money|Mathematics|Measurement|8|9|0.042
mt_ghK1mnEstc|Halves and quarters (age 8+)|Mathematics|Measurement|8|9|0.052
mt_-af65bxfdp|Measuring Liquids & Masses|Mathematics|Measurement|8|9|0.03
mt_IL86kadLSS|Numbers on a number line|Mathematics|Measurement|8|9|0.059
mt_WtcFrxGOgw|Perimeters of polygons|Mathematics|Measurement|8|9|0.074
mt_UNzojLkNdm|Telling time to the minute (age 8+)|Mathematics|Measurement|8|9|0.052
mt_GzcJEVkNRn|Understanding angles (age 8+)|Mathematics|Measurement|8|9|0.172
mt_6xNmQLzuqm|Understanding Area|Mathematics|Measurement|8|9|0.179
mt_Zks8xyInSG|Converting measurement units (age 9+)|Mathematics|Measurement|9|10|0.078
mt_eiB3-6pu6a|Estimating answers (age 9+)|Mathematics|Measurement|9|10|0.068
mt_NSC3LT_-ch|Estimating volume|Mathematics|Measurement|9|10|0.027
mt_5HV4mbgSGH|Fractions on a number line|Mathematics|Measurement|9|10|0.093
mt_42QD6nYjiZ|Measurement Line Plots|Mathematics|Measurement|9|10|0.064
mt_p6MhZJYYPN|Metric & Imperial Conversion|Mathematics|Measurement|9|10|0.064
mt_n0AlyLQwC9|Perimeter of Compound Shapes|Mathematics|Measurement|9|10|0.051
mt_2yas4Unc8o|Telling time to the minute (age 9+)|Mathematics|Measurement|9|10|0.079
mt_ML5t7n2-U8|Area of Triangles & Parallelograms|Mathematics|Measurement|10|11|0.157
mt_d7XktBQPxm|Counting Unit Cubes|Mathematics|Measurement|10|11|0.027
mt_2VpdPjvewx|Decimal place value|Mathematics|Measurement|10|11|0.104
mt_nTL-owFJTF|Estimating answers (age 10+)|Mathematics|Measurement|10|11|0.068
mt_SqhXQhAEUf|Measurement Conversions|Mathematics|Measurement|10|11|0.104
mt_IuHa5UI5od|Measuring length (age 10+)|Mathematics|Measurement|10|11|0.027
mt_3tPI0HqqcN|Miles & Kilometres|Mathematics|Measurement|10|11|0.122
mt_MJZA90uc6H|Perimeter (age 10+)|Mathematics|Measurement|10|11|0.051
mt_5TBUFnCy5-|Volume as additive|Mathematics|Measurement|10|11|0.12
mt_LpSuPgL31x|Division as equal sharing|Mathematics|Multiplication & Division|4|6|0.431
mt_GRWwTDZ3wD|Arrays for multiplication|Mathematics|Multiplication & Division|5|6|0.187
mt_PZ909yPrEC|Multiplication as repeated addition|Mathematics|Multiplication & Division|5|6|0.213
mt_C9ZfT-4cgn|Commutative Multiplication|Mathematics|Multiplication & Division|6|7|0.142
mt_wh3UqnWsa7|Multiplication as repeated addition (age 6+)|Mathematics|Multiplication & Division|6|7|0.083
mt_0u4KLbvBa1|Odd and even numbers|Mathematics|Multiplication & Division|6|7|0.008
mt_zOWwLxa77y|Reading ×, ÷, and = Symbols|Mathematics|Multiplication & Division|6|7|0.146
mt_HhuSDxwDNM|Times tables|Mathematics|Multiplication & Division|6|7|0.194
mt_B1zj1RwQ3a|Arrays for multiplication (age 7+)|Mathematics|Multiplication & Division|7|8|0.183
mt_EmR5n58jZt|Multi-Step Multiply & Divide|Mathematics|Multiplication & Division|7|8|0.101
mt_UTnDKQkVX5|Rows & Columns in Rectangles|Mathematics|Multiplication & Division|7|8|0.014
mt_wQ89AEXhz3|Times tables (age 7+)|Mathematics|Multiplication & Division|7|8|0.194
mt_DyGBW3ZHh3|Written Multiplication & Division|Mathematics|Multiplication & Division|7|8|0.157
mt_K5jM7vlVhA|All times tables to 12×12|Mathematics|Multiplication & Division|8|9|0.179
mt_GDG9_SZmsO|Division as Unknown Factor|Mathematics|Multiplication & Division|8|9|0.141
mt_nZkL5-XjRX|Factor Pairs & Commutativity|Mathematics|Multiplication & Division|8|9|0.092
mt_WX30dzi4dt|Fluent multiplication and division facts|Mathematics|Multiplication & Division|8|9|0.144
mt_pjfmCMMPjO|Mental multiplication and division|Mathematics|Multiplication & Division|8|9|0.029
mt_Zdv-b-iW5K|Multiplication and Division Word Problems|Mathematics|Multiplication & Division|8|9|0.022
mt_AR-K72OIIO|Multiply & Add Problems|Mathematics|Multiplication & Division|8|9|0.111
mt_isojCL9yy-|Multiplying by Tens|Mathematics|Multiplication & Division|8|9|0.034
mt_w6MxaaoMXZ|Patterns in Times Tables|Mathematics|Multiplication & Division|8|9|0.037
mt_Lb2ZnMdkYR|Properties of Operations|Mathematics|Multiplication & Division|8|9|0.145
mt_xZvDCYA5Ae|Unknown in Multiplication & Division|Mathematics|Multiplication & Division|8|9|0.018
mt_iNdrM2-oJf|What Division Means|Mathematics|Multiplication & Division|8|9|0.138
mt_gtTl3R5buH|What Multiplication Means|Mathematics|Multiplication & Division|8|9|0.182
mt_18fK9sQdIz|Written Multiplication|Mathematics|Multiplication & Division|8|9|0.159
mt_MCu_SNg_OW|Arrays for multiplication (age 9+)|Mathematics|Multiplication & Division|9|10|0.134
mt_p-nbe0w_lf|Division with remainders|Mathematics|Multiplication & Division|9|10|0.14
mt_FHIAv6dfhU|Factors, multiples, and primes|Mathematics|Multiplication & Division|9|11|0.092
mt_0Wg5F97osg|Factors, multiples, and primes (age 9+)|Mathematics|Multiplication & Division|9|10|0.029
mt_q9EaJc2FP8|Long multiplication|Mathematics|Multiplication & Division|9|10|0.179
mt_8A3pZNOp7Z|Mental multiplication and division (age 9+)|Mathematics|Multiplication & Division|9|10|0.029
mt_6-j1NO2ZUH|Multiplicative Comparison|Mathematics|Multiplication & Division|9|10|0.023
mt_U4cIBXVug4|Multiplicative Comparison|Mathematics|Multiplication & Division|9|10|0.044
mt_LlMl2PbaZe|Multiplying and dividing|Mathematics|Multiplication & Division|9|10|0.077
mt_y1XCVsIelg|Prime numbers|Mathematics|Multiplication & Division|9|10|0.027
mt_A-FyLLLLzy|Shape patterns|Mathematics|Multiplication & Division|9|10|0.037
mt_gxCIASSezX|Square and cube numbers|Mathematics|Multiplication & Division|9|10|0.019
mt_ZOJ6EbdPOb|Understanding fractions|Mathematics|Multiplication & Division|9|10|0.037
mt_8jFSnXxqQD|Brackets in Expressions|Mathematics|Multiplication & Division|10|11|0.14
mt_SoDP1fSQEB|Decimal place value|Mathematics|Multiplication & Division|10|11|0.12
mt_FvEq4heNBx|Dividing by two-digit numbers|Mathematics|Multiplication & Division|10|11|0.07
mt_lU-2aTRB9f|Division with Decimals|Mathematics|Multiplication & Division|10|11|0.12
mt_WsM4EmdOLe|Division with remainders (age 10+)|Mathematics|Multiplication & Division|10|11|0.145
mt_ilPrU0cbtT|Estimation to check answers to calculations|Mathematics|Multiplication & Division|10|11|0.09
mt_XLP1IM3Qbb|Long multiplication (age 10+)|Mathematics|Multiplication & Division|10|11|0.175
mt_wPgpMJ0-PA|Multiplying and dividing (age 10+)|Mathematics|Multiplication & Division|10|11|0.1
mt_RXnyhCRYXA|Multi-step problems: choosing operations|Mathematics|Multiplication & Division|10|11|0.112
mt_jHgRQ4hR0g|Order of operations|Mathematics|Multiplication & Division|10|11|0.138
mt_vmW2cb5c7A|Ratio (age 10+)|Mathematics|Multiplication & Division|10|11|0.075
mt_QU5R7Aajy9|Rounding Answers|Mathematics|Multiplication & Division|10|11|0.145
mt_4WaKWECpcv|Writing Number Sentences|Mathematics|Multiplication & Division|10|11|0.129
mt_xhoOWnhtHq|Factors, multiples, and primes (age 11+)|Mathematics|Multiplication & Division|11|12|0.027
mt_X5cypSGoGU|Ratio (age 11+)|Mathematics|Multiplication & Division|11|12|0.083
mt_rxInpOQ74w|Sign Rules for Multiplication|Mathematics|Multiplication & Division|11|13|0.023
mt_VUQNveSYjQ|Using inverse operations|Mathematics|Multiplication & Division|11|12|0.111
mt_9IzhGUZ30z|Number Words to Twenty|Mathematics|Number Representation & Place Value|5|6|0.021
mt_x8TshvbbQT|Reading and writing numbers to 100|Mathematics|Number Representation & Place Value|5|6|0.012
mt_fR0UtsSREU|Reading and writing numbers to 20|Mathematics|Number Representation & Place Value|5|6|0.592
mt_xmmgAzxe5j|The teen numbers|Mathematics|Number Representation & Place Value|5|7|0.408
mt_kw7xmp68rU|10 More or 10 Less|Mathematics|Number Representation & Place Value|6|7|0.031
mt_r0VXbfAmsH|A Ten Is Ten Ones|Mathematics|Number Representation & Place Value|6|7|0.406
mt_U0waNfD8PB|Comparing and ordering numbers|Mathematics|Number Representation & Place Value|6|7|0.141
mt_76SPWvdI7r|Number Words to 100|Mathematics|Number Representation & Place Value|6|7|0.023
mt_kJGCjnuelW|Place value understanding and number facts|Mathematics|Number Representation & Place Value|6|7|0.019
mt_XV0B4kWwqL|Reading and writing numbers to 120|Mathematics|Number Representation & Place Value|6|7|0.01
mt_9L3NQqgqRd|Representing Numbers|Mathematics|Number Representation & Place Value|6|8|0.059
mt_zfy1gOEewd|The multiples of 10|Mathematics|Number Representation & Place Value|6|7|0.014
mt_THl9GLxwoL|The two digits of a two-digit number|Mathematics|Number Representation & Place Value|6|7|0.404
mt_izien3ZX51|10 or 100 More or Less|Mathematics|Number Representation & Place Value|7|8|0.023
mt_8gy7uxRlF6|A Hundred Is Ten Tens|Mathematics|Number Representation & Place Value|7|8|0.327
mt_hniI4E-OCE|Odd or Even|Mathematics|Number Representation & Place Value|7|8|0.007
mt_AQcVRBddko|Ordering Numbers to 1000|Mathematics|Number Representation & Place Value|7|8|0.068
mt_98c2qwEF7Q|Place Value to 1000|Mathematics|Number Representation & Place Value|7|8|0.018
mt_VFsuftfvYM|Reading and writing numbers to 1000|Mathematics|Number Representation & Place Value|7|8|0.03
mt_R2ccrI-nKD|The multiples of 100|Mathematics|Number Representation & Place Value|7|8|0.057
mt_aPBzD28_mT|The three digits of a three-digit number|Mathematics|Number Representation & Place Value|7|8|0.311
mt_9XVFje6Tyr|1000 More or Less|Mathematics|Number Representation & Place Value|8|9|0.021
mt_MHaiUd2FLA|Comparing Large Numbers|Mathematics|Number Representation & Place Value|8|9|0.06
mt_vXRzMbiPff|Negative Numbers|Mathematics|Number Representation & Place Value|8|9|0.06
mt_lC_Q5mSL_I|Numbers to 10,000|Mathematics|Number Representation & Place Value|8|9|0.053
mt_jY7uf0Cb7o|Place value of each digit|Mathematics|Number Representation & Place Value|8|9|0.122
mt__sMrmOv3bx|Place Value Problem-Solving|Mathematics|Number Representation & Place Value|8|9|0.042
mt_MewIRdzpzz|Roman numerals to 100|Mathematics|Number Representation & Place Value|8|9|0.016
mt_NLSfvB9vUl|Rounding to 10, 100, 1000|Mathematics|Number Representation & Place Value|8|9|0.056
mt_tAtMET4EIU|Counting forwards and backwards (age 9+)|Mathematics|Number Representation & Place Value|9|10|0.022
mt_1KkvzwYxbR|Negative numbers in context|Mathematics|Number Representation & Place Value|9|10|0.06
mt_QqG6IdmTSE|Place Value × 10 Pattern|Mathematics|Number Representation & Place Value|9|10|0.104
mt_JwP9QFv6gQ|Reading and writing numbers (age 9+)|Mathematics|Number Representation & Place Value|9|10|0.062
mt_To9HdLy8vq|Roman numerals to 1000|Mathematics|Number Representation & Place Value|9|10|0.016
mt_5NwqN6pf_A|Rounding Large Numbers|Mathematics|Number Representation & Place Value|9|10|0.055
mt_xMt1TLTs--|Working with Large Numbers|Mathematics|Number Representation & Place Value|9|10|0.052
mt__casygEB85|Decimal place value|Mathematics|Number Representation & Place Value|10|11|0.093
mt_RVK655t391|Measuring temperature|Mathematics|Number Representation & Place Value|10|11|0.06
mt_XNmGwNggdU|Numbers to Ten Million|Mathematics|Number Representation & Place Value|10|11|0.103
mt_HLUqHJ9Y7n|Patterns with Powers of Ten|Mathematics|Number Representation & Place Value|10|11|0.059
mt_EDgw64OmfA|Place Value × 10 and ÷ 10|Mathematics|Number Representation & Place Value|10|11|0.126
mt_Ac7oMWhyPw|Reading and writing numbers (age 10+)|Mathematics|Number Representation & Place Value|10|11|0.108
mt_Gag_h98jWP|Reading and writing numbers to 10,000,000|Mathematics|Number Representation & Place Value|10|11|0.1
mt_lNGpnILM5C|Reading Decimal Places|Mathematics|Number Representation & Place Value|10|11|0.097
mt_U9sme87C32|Decimal place value (age 11+)|Mathematics|Number Representation & Place Value|11|13|0.089
mt_PsylzZ9lHW|Fractions on a number line|Mathematics|Number Representation & Place Value|11|12|0.097
mt_uDJY0X0hgo|Fractions on a number line (age 11+)|Mathematics|Number Representation & Place Value|11|12|0.105
mt_RWUY7_IXvw|Numbers on a number line|Mathematics|Number Representation & Place Value|11|12|0.023
mt_hCVPYlF-7Y|Square and cube numbers|Mathematics|Number Representation & Place Value|11|14|0.083
mt_VVn1IXjkzn|Estimating by rounding|Mathematics|Number Representation & Place Value|12|14|0.089
mt_bO-njVOige|Powers of Ten Notation|Mathematics|Number Representation & Place Value|12|14|0.082
mt_b4lbTOJYwI|Number Sets & Infinity|Mathematics|Number Representation & Place Value|13|14|0.123
mt_xSgAgg9Ej_|Equally Likely Outcomes|Mathematics|Probability|9|10|0.018
mt_iFFKZd-Vgv|Likelihood Language|Mathematics|Probability|9|10|0.019
mt_UcGn2hjhYU|Ordering Likelihoods|Mathematics|Probability|9|10|0.018
mt_-c4Ca_nBzX|Probability as a Fraction|Mathematics|Probability|9|10|0.04
mt_J4j7d3iAfg|Simple Chance Experiments|Mathematics|Probability|9|10|0.027
mt_Zt30Gxi-qp|Calculating Simple Probability|Mathematics|Probability|10|11|0.049
mt_-bMnJcPJy8|Experimental vs Theoretical|Mathematics|Probability|10|11|0.042
mt_3fwYu7imd4|Probabilities Sum to One|Mathematics|Probability|10|11|0.045
mt_t0g2SlP404|The 0-to-1 Probability Scale|Mathematics|Probability|10|11|0.049
mt_XfyqXLqzpx|Complementary events|Mathematics|Probability|11|13|0.155
mt_sHJqh6UUya|Experimental probability|Mathematics|Probability|11|13|0.152
mt_vmQJAtAFuy|The Probability Scale|Mathematics|Probability|11|13|0.155
mt_1YwOCMMwD8|Sets & Venn Diagrams|Mathematics|Probability|12|14|0.155
mt_GDtFU5fyUv|Tree diagrams|Mathematics|Probability|12|14|0.157
mt_eSv_w46u6H|Venn Diagrams and Counting Outcomes|Mathematics|Probability|12|13|0.153
mt_ePXg_XyCKU|Bar Models for Ratios|Mathematics|Ratio & Proportion|9|12|0.04
mt_ESgc4YBw-a|Percentages (age 9+)|Mathematics|Ratio & Proportion|9|11|0.04
mt_PNSyfH56eQ|Calculating Percentages|Mathematics|Ratio & Proportion|10|11|0.142
mt_h0gJcSuwdL|Ratio Problems|Mathematics|Ratio & Proportion|10|11|0.088
mt_2OtRUM_0zW|Scale and similar shapes|Mathematics|Ratio & Proportion|10|11|0.137
mt_FnUJMXPUZX|Understanding fractions|Mathematics|Ratio & Proportion|10|11|0.081
mt_kLQOzZYrd5|Compound Units|Mathematics|Ratio & Proportion|11|14|0.261
mt_nOCPx5qw0Z|Dividing Quantities by Ratio|Mathematics|Ratio & Proportion|11|13|0.079
mt_xAf2bu9wYK|One Quantity as a Fraction|Mathematics|Ratio & Proportion|11|12|0.144
mt_ALUrJpY0cZ|Percentages as Fractions|Mathematics|Ratio & Proportion|11|13|0.131
mt_ATYLKt0je-|Proportional Reasoning Vocabulary|Mathematics|Ratio & Proportion|11|14|0.036
mt_FspV_imUGK|Proportion Graphs|Mathematics|Ratio & Proportion|11|14|0.015
mt_XWSGuFW7It|Ratio Notation|Mathematics|Ratio & Proportion|11|12|0.082
mt_1badik7iKJ|Scale and similar shapes (age 11+)|Mathematics|Ratio & Proportion|11|13|0.172
mt_tpT9brpI6D|Unit Conversions|Mathematics|Ratio & Proportion|11|12|0.104
mt_iEXqN48w3x|Percentages (age 12+)|Mathematics|Ratio & Proportion|12|14|0.135
mt_5mIcmKRCgA|Proportion|Mathematics|Ratio & Proportion|12|14|0.237
mt_yK51ZnKA8m|Ratio Notation and Relationships|Mathematics|Ratio & Proportion|12|14|0.235
mt_kvrvpQris4|Expressing Feelings with Words|Personal & Social Development|Emotional Literacy|5|7|0.078
mt_ggcamLzXAy|Feelings Change and Differ|Personal & Social Development|Emotional Literacy|5|7|0.111
mt_LhkP_KKIRS|Naming Basic Emotions|Personal & Social Development|Emotional Literacy|5|7|0.138
mt_9Y5-GjF2B0|Triggers and Causes of Feelings|Personal & Social Development|Emotional Literacy|5|7|0.088
mt_MOY_2Cqalz|Emotion Vocabulary|Personal & Social Development|Emotional Literacy|7|9|0.051
mt_E5ju6kQSu3|Hidden and Masked Feelings|Personal & Social Development|Emotional Literacy|7|9|0.015
mt_Ytd8XC3eQr|How Emotions Feel in Your Body|Personal & Social Development|Emotional Literacy|7|9|0.019
mt_rymBfJmvFl|Mild to Strong Emotions|Personal & Social Development|Emotional Literacy|7|9|0.016
mt_nIl1kKZHsk|Culture and Experience Shape Emotions|Personal & Social Development|Emotional Literacy|9|11|0.015
mt_cEQqskOaoo|Emotional Patterns Over Time|Personal & Social Development|Emotional Literacy|9|11|0.124
mt_KA5j5OeGvw|Emotions and Decision-Making|Personal & Social Development|Emotional Literacy|9|11|0.085
mt_dlm3NspUyy|Mixed and Conflicting Emotions|Personal & Social Development|Emotional Literacy|9|11|0.014
mt_gf4RUcACLg|Brain Science of Emotions|Personal & Social Development|Emotional Literacy|11|12|0.086
mt_p-8Hlf6_9k|Identity and Belonging in Adolescence|Personal & Social Development|Emotional Literacy|12|13|0.094
mt_mydcMoa8gN|Emotional Intelligence|Personal & Social Development|Emotional Literacy|13|14|0.131
mt_lAvS72LOUO|Everyday Kindness and Care|Personal & Social Development|Empathy & Social Awareness|5|7|0.019
mt_wzUzVEBqJb|Other People's Feelings and Thoughts|Personal & Social Development|Empathy & Social Awareness|5|7|0.04
mt_OJVkWvIaM_|Similarities & Differences|Personal & Social Development|Empathy & Social Awareness|5|7|0.018
mt_wRlf0g2MbB|Vocabulary: understanding others|Personal & Social Development|Empathy & Social Awareness|5|8|0.041
mt_S7UTAhptLi|Different Lives and Experiences|Personal & Social Development|Empathy & Social Awareness|7|9|0.025
mt_mDp-1vlL3R|Fairness, Equality and Equity|Personal & Social Development|Empathy & Social Awareness|7|9|0.014
mt_9NQEiYLQA3|Seeing Someone Else's Point of View|Personal & Social Development|Empathy & Social Awareness|7|9|0.042
mt_a6AYrbb7x4|Vocabulary: social awareness|Personal & Social Development|Empathy & Social Awareness|7|11|0.037
mt_HFN1pGASpZ|Prejudice and Discrimination|Personal & Social Development|Empathy & Social Awareness|9|11|0.033
mt_cOknxrYhwL|Questioning Your Own Biases|Personal & Social Development|Empathy & Social Awareness|9|11|0.071
mt_2oswCNuapH|Stereotypes and Individual Differences|Personal & Social Development|Empathy & Social Awareness|9|11|0.023
mt_DkzsZdyaL2|The world contains many cultures, traditions|Personal & Social Development|Empathy & Social Awareness|9|11|0.014
mt_oqvJJKCJXw|Systemic Inequality and Allyship|Personal & Social Development|Empathy & Social Awareness|11|12|0.027
mt_VA126P6Wp5|Sympathy Versus Empathy|Personal & Social Development|Empathy & Social Awareness|12|13|0.068
mt_5XLhiqmocP|Global Citizenship|Personal & Social Development|Empathy & Social Awareness|13|14|0.07
mt_PdYlsA33jB|Asking for Help|Personal & Social Development|Friendship & Cooperation|5|7|0.011
mt_YbX3LD0Eca|Listening to Others|Personal & Social Development|Friendship & Cooperation|5|7|0.022
mt_HBcvu0UxYe|Makes someone a good friend|Personal & Social Development|Friendship & Cooperation|5|7|0.016
mt_FwI7q7DSIx|Taking Turns and Sharing|Personal & Social Development|Friendship & Cooperation|5|7|0.012
mt_NS5t-Jzlh8|Vocabulary: working with others|Personal & Social Development|Friendship & Cooperation|5|8|0.023
mt_Ag9NSWJu-X|Communication Vocabulary|Personal & Social Development|Friendship & Cooperation|7|11|0.018
mt_X7Tu94-a2m|Friendships change over time|Personal & Social Development|Friendship & Cooperation|7|9|0.022
mt_iWGnyUyN2j|Resolving Disagreements with Friends|Personal & Social Development|Friendship & Cooperation|7|9|0.034
mt_w4nSIDhIgC|Roles in a Group|Personal & Social Development|Friendship & Cooperation|7|9|0.018
mt_QxsoqVUt6u|Working Well in a Group|Personal & Social Development|Friendship & Cooperation|7|9|0.022
mt_rqLMfiw61L|Assertive Communication|Personal & Social Development|Friendship & Cooperation|9|11|0.048
mt_33zncDHC3N|Giving and Receiving Feedback|Personal & Social Development|Friendship & Cooperation|9|11|0.071
mt_AbnwmKD8oe|Helping Others Resolve Conflicts|Personal & Social Development|Friendship & Cooperation|9|11|0.036
mt_z98J_Zg2L3|Self-Reflection in Relationships|Personal & Social Development|Friendship & Cooperation|9|11|0.081
mt_nqM2OW0Qlm|Social Cues and Group Dynamics|Personal & Social Development|Friendship & Cooperation|11|12|0.081
mt_NCrbQe0LdB|Honest Conversations and Conflict Repair|Personal & Social Development|Friendship & Cooperation|12|13|0.089
mt_8StiXnYq1u|Leadership Styles and Influence|Personal & Social Development|Friendship & Cooperation|13|14|0.089
mt_UHQfb-n-w3|Actions and Their Consequences|Personal & Social Development|Responsible Decision-Making|5|7|0.04
mt_q3vRl4dddK|Everyday Safety Awareness|Personal & Social Development|Responsible Decision-Making|5|7|0.005
mt_Wc6cOTQ1bA|Right and Wrong Choices|Personal & Social Development|Responsible Decision-Making|5|7|0.025
mt_rkrG2w7WXI|Rules and agreements exist|Personal & Social Development|Responsible Decision-Making|5|7|0.012
mt_uTKgmWqSoI|Vocabulary: making decisions and keeping safe|Personal & Social Development|Responsible Decision-Making|5|8|0.041
mt_zIzJGkaj0Q|Basic digital citizenship|Personal & Social Development|Responsible Decision-Making|7|9|0.019
mt_yCmYV9ruQu|Bystanders and Upstanders|Personal & Social Development|Responsible Decision-Making|7|9|0.03
mt_RhntJz7p_6|Stop, Think, Then Choose|Personal & Social Development|Responsible Decision-Making|7|9|0.088
mt_I9iSzpGRn5|Understanding Bullying|Personal & Social Development|Responsible Decision-Making|7|9|0.03
mt_h-z88yf9Pn|Vocabulary: ethics and citizenship|Personal & Social Development|Responsible Decision-Making|7|11|0.036
mt_h_shhH-6DC|Community Rights and Responsibilities|Personal & Social Development|Responsible Decision-Making|9|11|0.014
mt_6xj94tmpi-|Difficult Ethical Choices|Personal & Social Development|Responsible Decision-Making|9|11|0.152
mt_RNeEF1JU4J|Ethics in Real-World Issues|Personal & Social Development|Responsible Decision-Making|9|11|0.185
mt_JivEBTD_KV|Peer Pressure and Resisting It|Personal & Social Development|Responsible Decision-Making|9|11|0.107
mt_JiZ3H90Xg8|Risk, Uncertainty, and Cognitive Bias|Personal & Social Development|Responsible Decision-Making|11|12|0.185
mt_WtO50EZQkf|Online Identity and Misinformation|Personal & Social Development|Responsible Decision-Making|12|13|0.187
mt_LPYPuSaxv_|Ethical Frameworks and Moral Reasoning|Personal & Social Development|Responsible Decision-Making|13|14|0.202
mt_69hFD2NgGe|Naming Your Feelings|Personal & Social Development|Self-Awareness|5|6|0.031
mt_H4YZ1rSKP3|Vocabulary: self|Personal & Social Development|Self-Awareness|5|10|0.029
mt_TU3BcLOgiV|Feelings Versus Actions|Personal & Social Development|Self-Awareness|6|8|0.031
mt_H8dEMH_wik|Patterns in Your Own Reactions|Personal & Social Development|Self-Awareness|7|9|0.037
mt_rpug2tkYhb|Your Impact on Others|Personal & Social Development|Self-Awareness|8|9|0.056
mt_Mb1JUJmnbX|Questioning First Impressions|Personal & Social Development|Self-Awareness|9|10|0.052
mt_bkMDDstwwG|Personal Growth Over Time|Personal & Social Development|Self-Awareness|10|11|0.049
mt_aS-Gdh-MHx|Coping with Life Changes|Personal & Social Development|Self-Regulation & Resilience|5|7|0.014
mt_UGf6jICEhs|Learning from Mistakes|Personal & Social Development|Self-Regulation & Resilience|5|7|0.026
mt_nNDX_jZ-cb|Patience and Delayed Gratification|Personal & Social Development|Self-Regulation & Resilience|5|7|0.004
mt_Iwg2diBSyW|Simple Calming Strategies|Personal & Social Development|Self-Regulation & Resilience|5|7|0.088
mt_SeNxOZTHCN|Words for Big Feelings|Personal & Social Development|Self-Regulation & Resilience|5|8|0.094
mt_miGrca8zaS|Breaking Tasks into Steps|Personal & Social Development|Self-Regulation & Resilience|7|9|0.045
mt_j8Pv3s7TZR|Choosing the Right Coping Strategy|Personal & Social Development|Self-Regulation & Resilience|7|9|0.022
mt_pAuo9Op89t|Growth Mindset|Personal & Social Development|Self-Regulation & Resilience|7|9|0.037
mt_35-DhMh_Yr|Positive Self-Talk|Personal & Social Development|Self-Regulation & Resilience|7|9|0.03
mt_i1kk9HDctI|Vocabulary: resilience and self|Personal & Social Development|Self-Regulation & Resilience|7|10|0.031
mt_Jd2aWEUJ9G|Personal Coping Toolkit|Personal & Social Development|Self-Regulation & Resilience|9|11|0.115
mt_cJjnPjuvCU|Personal Goal-Setting|Personal & Social Development|Self-Regulation & Resilience|9|11|0.09
mt_Amw5ikSSQI|Resilience and Bouncing Back|Personal & Social Development|Self-Regulation & Resilience|9|11|0.092
mt_HoJGVsMO7H|Time and Attention Management|Personal & Social Development|Self-Regulation & Resilience|9|11|0.037
mt_0VOZSVjo6c|Good Stress and Bad Stress|Personal & Social Development|Self-Regulation & Resilience|11|12|0.089
mt_0ewYhTSHtP|Habits and Motivation|Personal & Social Development|Self-Regulation & Resilience|12|13|0.105
mt__J2BO4V95l|Growth Through Adversity|Personal & Social Development|Self-Regulation & Resilience|13|14|0.115
mt_pwo81ls_J-|Animal Camouflage|Science|Animals of the World|5|7|0.038
mt_oLHXfLujmh|Animal Homes|Science|Animals of the World|5|7|0.134
mt_goZW_hQUa4|Animal Record-Holders|Science|Animals of the World|5|7|0.001
mt_v3Vz_Pgjjv|Animals Everywhere|Science|Animals of the World|5|7|0.153
mt_-vsLvsxp0L|How Animals Have Babies|Science|Animals of the World|5|7|0.053
mt_V_wIdRZLsG|Nocturnal Animals|Science|Animals of the World|5|7|0.04
mt_muxjw0fxxN|Wild, Farm & Pet Animals|Science|Animals of the World|5|7|0.041
mt_wHN14Unk7h|Animal Communication|Science|Animals of the World|7|9|0.016
mt_bK84sPehyP|Animal Migration|Science|Animals of the World|7|9|0.044
mt_0zqOTjjW2k|Desert Animals|Science|Animals of the World|7|9|0.036
mt_D4lyx0iYyB|Polar Animals|Science|Animals of the World|7|9|0.049
mt_Bztatrv-_v|Predator Hunting Strategies|Science|Animals of the World|7|9|0.042
mt_DCelLx_H1A|Rainforest Animals|Science|Animals of the World|7|9|0.03
mt_YynJoQcm_M|Savanna & Grassland Animals|Science|Animals of the World|7|9|0.041
mt_R7LEuZjTmx|The World of Minibeasts|Science|Animals of the World|7|9|0.033
mt_fpPLWFIRVo|Animal Intelligence|Science|Animals of the World|9|11|0.027
mt_NDZYiLvApW|Biodiversity|Science|Animals of the World|9|11|0.181
mt_5S4byWDX6n|Endangered & Extinct Species|Science|Animals of the World|9|11|0.178
mt_CBxOcjh69x|Invasive Species|Science|Animals of the World|9|11|0.168
mt_pWwV_8OgXD|Protecting Endangered Animals|Science|Animals of the World|9|11|0.179
mt_EaWjCyn8W2|Structural Adaptations|Science|Animals of the World|9|11|0.129
mt_H8OgKZbgGe|Symbiosis|Science|Animals of the World|9|11|0.124
mt_mKNmXqz_Oo|The Red Queen Hypothesis|Science|Animals of the World|11|12|0.109
mt_ot9rcUwBtK|Deep-Sea Survival|Science|Animals of the World|12|13|0.107
mt_YNrrNE23dZ|Sexual Selection|Science|Animals of the World|12|13|0.118
mt_44HkROUnzE|The Biodiversity Crisis|Science|Animals of the World|12|14|0.179
mt_fqAkSv3cUE|Grouping Species Using DNA|Science|Animals of the World|13|14|0.178
mt_u0TeRwRII_|Dinosaur Sizes|Science|Dinosaurs & Paleontology|5|7|0.016
mt_dpM1l5IOk6|Dinosaurs Were Real|Science|Dinosaurs & Paleontology|5|7|0.078
mt_BnabTHkNIp|Famous Dinosaur Species|Science|Dinosaurs & Paleontology|5|7|0.037
mt_bKlnc7dyVK|Fossils & Palaeontologists|Science|Dinosaurs & Paleontology|5|7|0.066
mt_DJh2JPwTf6|Plant-Eaters vs Meat-Eaters|Science|Dinosaurs & Paleontology|5|7|0.026
mt_JednrdYqpt|Real Dinosaurs vs Fiction|Science|Dinosaurs & Paleontology|5|7|0.016
mt_oH1XC8aQYn|Dinosaurs Around the World|Science|Dinosaurs & Paleontology|7|9|0.008
mt_1dXhJp6qLJ|Fossilised Dinosaur Dung|Science|Dinosaurs & Paleontology|7|9|0.03
mt_fKwgN61ttR|Fossils Reveal Ancient Environments|Science|Dinosaurs & Paleontology|7|9|0.044
mt_iycQEai3dK|How Fossils Form|Science|Dinosaurs & Paleontology|7|9|0.033
mt_excSPNHJWZ|Mary Anning, Fossil Hunter|Science|Dinosaurs & Paleontology|7|9|0.003
mt_Wpvuz3mvBq|Reading Dinosaur Trackways|Science|Dinosaurs & Paleontology|7|9|0.027
mt_uQljqc0J5j|The Mesozoic Era|Science|Dinosaurs & Paleontology|7|9|0.016
mt_1VSFoM44JU|Types of Fossils|Science|Dinosaurs & Paleontology|7|9|0.029
mt_6Z42wJaKYG|Fossils as Evidence|Science|Dinosaurs & Paleontology|8|11|0.074
mt_T8JGTJ-oNI|Birds Evolved from Dinosaurs|Science|Dinosaurs & Paleontology|9|11|0.1
mt_0T0Zf0YG6k|Changing Scientific Knowledge|Science|Dinosaurs & Paleontology|9|11|0.287
mt_yrSdVrXrsF|Dinosaur Hip Groups|Science|Dinosaurs & Paleontology|9|11|0.023
mt_JBWMqZVO7S|How Palaeontologists Work|Science|Dinosaurs & Paleontology|9|11|0.031
mt_M8UQTURODF|Palaeoart & Speculation|Science|Dinosaurs & Paleontology|9|11|0.092
mt_cSPtyLF3q1|Reading Cladograms|Science|Dinosaurs & Paleontology|9|11|0.105
mt_EGIlsfHxb6|Rock Layers & Relative Dating|Science|Dinosaurs & Paleontology|9|11|0.033
mt_QHKqckBdAk|The K-Pg Extinction Event|Science|Dinosaurs & Paleontology|9|11|0.011
mt_gTDqxYkLs9|Life Changed Over Time|Science|Dinosaurs & Paleontology|10|11|0.089
mt_mqQ-DtH5m-|Dinosaur-to-Bird Transition|Science|Dinosaurs & Paleontology|11|13|0.096
mt_bHbpLW1HUg|Radiometric Dating|Science|Dinosaurs & Paleontology|11|13|0.042
mt_IP0PTVfTXp|Mass Extinctions in Earth History|Science|Dinosaurs & Paleontology|12|14|0.228
mt_8_BxtNDrLZ|Reconstructing Ancient Ecosystems|Science|Dinosaurs & Paleontology|12|14|0.274
mt_tGZ2sMzMGz|Megafauna Extinction & De-Extinction|Science|Dinosaurs & Paleontology|13|14|0.228
mt_qixeaiswFP|How Organisms Shape Habitats|Science|Earth's Systems|5|6|0.005
mt_HZvTriQWTh|Local weather patterns|Science|Earth's Systems|5|6|0.022
mt_go5i87u2b9|Seasonal changes|Science|Earth's Systems|5|6|0.208
mt_zCGwH1OQZa|Evaporation and condensation|Science|Earth's Systems|7|9|0.015
mt_mwirOvigWD|How fossils form|Science|Earth's Systems|7|8|0.067
mt_m6UaSmrQVG|Preventing Erosion|Science|Earth's Systems|7|8|0.03
mt_R6YoRXkRxS|Properties of materials|Science|Earth's Systems|7|8|0.088
mt_yhhprm7dZK|Rocks and soil|Science|Earth's Systems|7|8|0.01
mt_KsKLVW_ssY|Shapes of land and water|Science|Earth's Systems|7|8|0.127
mt_nRF_VRntrW|Where water is found on Earth|Science|Earth's Systems|7|8|0.098
mt_NYsz6QgaaE|Seasonal changes (age 8+)|Science|Earth's Systems|8|9|0.036
mt_Gm12BzcCfX|Weather vs climate|Science|Earth's Systems|8|9|0.04
mt_vAP_A986IQ|Erosion and weathering|Science|Earth's Systems|9|10|0.036
mt_-G6erQvLig|Finding patterns in data|Science|Earth's Systems|9|10|0.048
mt_bqL8DD1SbV|Types of rocks|Science|Earth's Systems|9|11|0.022
mt_LKagN9GJPX|Earth's atmosphere|Science|Earth's Systems|10|11|0.141
mt_0_K-GrKQpd|Rock layers and Earth's history|Science|Earth's Systems|10|11|0.03
mt_LsY4-T2fU7|Salt Water vs Fresh Water|Science|Earth's Systems|10|11|0.075
mt_e6PP4ip39V|Plants and animals in their habitats|Science|Ecosystems & Habitats|5|6|0.008
mt_deexfCHU9m|Reducing Human Impact|Science|Ecosystems & Habitats|5|6|0.008
mt_cM8YS6NXqi|Habitats & Basic Needs|Science|Ecosystems & Habitats|6|8|0.14
mt_Fw0bbM1e_g|Habitat Vocabulary|Science|Ecosystems & Habitats|6|8|0.12
mt_Sa48W7KXB5|Living, Dead & Never Alive|Science|Ecosystems & Habitats|6|7|0.141
mt_ppENoD8vf1|Local Plants & Animals|Science|Ecosystems & Habitats|6|8|0.045
mt_EygMHKs8Ed|Simple Food Chains|Science|Ecosystems & Habitats|6|7|0.122
mt_i4bDqjyglj|Animal Groups & Survival|Science|Ecosystems & Habitats|8|9|0.03
mt_Wyd-l-6H7G|Changing Environments|Science|Ecosystems & Habitats|8|9|0.111
mt_brgde1Vx0P|Classification Keys|Science|Ecosystems & Habitats|8|9|0.053
mt_M7XhBBzYof|Ecology Vocabulary|Science|Ecosystems & Habitats|8|10|0.026
mt_oB-L8EVdIP|Food Chains & Energy Transfer|Science|Ecosystems & Habitats|8|9|0.066
mt_AylKwhbDWM|Grouping Living Things|Science|Ecosystems & Habitats|8|9|0.056
mt_YB0qF5KX9C|Human impact on environments|Science|Ecosystems & Habitats|8|11|0.042
mt_uVaS12lN1i|Reading Food Web Diagrams|Science|Ecosystems & Habitats|8|9|0.021
mt_A1Xfu5p5KT|Animal Life Cycles|Science|Ecosystems & Habitats|9|10|0.066
mt_yNWt3GQBNp|Plant & Animal Reproduction|Science|Ecosystems & Habitats|9|10|0.066
mt_IY3KwGLZgk|Classifying Organisms|Science|Ecosystems & Habitats|10|11|0.053
mt_7e-lG7YOWa|Communities Protecting Resources|Science|Ecosystems & Habitats|10|11|0.049
mt_B8lX8OCzGu|Evidence-Based Classification|Science|Ecosystems & Habitats|10|11|0.062
mt_0ajzcoKAKw|Matter Cycling in Ecosystems|Science|Ecosystems & Habitats|10|11|0.186
mt_BOG5zRYtQz|Energy Loss Between Levels|Science|Ecosystems & Habitats|11|12|0.047
mt_URTJbS3hhs|Food Webs & Interdependence|Science|Ecosystems & Habitats|11|12|0.063
mt_wWpa5fFDZP|Pollination & Pollinator Decline|Science|Ecosystems & Habitats|11|12|0.052
mt_V2lNzEex_a|The Water Cycle|Science|Ecosystems & Habitats|11|12|0.021
mt_xSs0xAd6i1|Biodiversity & Resilience|Science|Ecosystems & Habitats|12|14|0.049
mt_6aJUzBYGNs|Chromosomes, Genes & DNA|Science|Ecosystems & Habitats|12|13|0.016
mt_ohUnzoI_nx|Evidence for Evolution|Science|Ecosystems & Habitats|12|14|0.145
mt_-r3B4FQyX3|Extinction & Rapid Change|Science|Ecosystems & Habitats|12|14|0.224
mt_rOqo-8GeKt|Genetic Mutation|Science|Ecosystems & Habitats|12|14|0.01
mt_FuVEZ1Ac9s|How Natural Selection Works|Science|Ecosystems & Habitats|12|14|0.149
mt_JSUGQ5Repv|Species Distribution & Change|Science|Ecosystems & Habitats|12|13|0.053
mt_Be1A88GUpu|The Carbon Cycle|Science|Ecosystems & Habitats|12|13|0.205
mt_YvCgDM0Scg|Toxins Building Up in Food Chains|Science|Ecosystems & Habitats|12|13|0.047
mt_k1HXbEwG8f|Variation in Species|Science|Ecosystems & Habitats|12|13|0.052
mt_o7FJPDsHiW|Predicting Inherited Traits|Science|Ecosystems & Habitats|13|14|0.004
mt_2agkUcdah9|Building shade from the sun|Science|Energy|5|6|0.019
mt_iGSfQg3g5c|Sunlight warms things up|Science|Energy|5|6|0.057
mt_akBotspaf2|Naming types of energy|Science|Energy|7|9|0.063
mt_DA7-JYRvtP|Building a simple circuit|Science|Energy|8|9|0.066
mt_d-EKO-pKkP|Conductors and insulators|Science|Energy|8|9|0.004
mt_Hah24nbToi|How switches work|Science|Energy|8|9|0.016
mt_9nxyFoYD_b|What uses electricity at home|Science|Energy|8|9|0.066
mt_NNNbPccwB4|Will the bulb light up?|Science|Energy|8|9|0.016
mt_K1-HopEJAB|Building an energy-converting device|Science|Energy|9|10|0.011
mt_NzCNuABT3E|Circuit vocabulary|Science|Energy|9|11|0.012
mt_X_aDUBh-HF|How energy travels around|Science|Energy|9|10|0.068
mt_loYPGHJ8lm|Reading and drawing circuit diagrams|Science|Energy|9|10|0.021
mt_2Um22lTBZV|Speed and energy|Science|Energy|9|10|0.018
mt_1MLi55bPnt|What happens when things collide|Science|Energy|9|10|0.005
mt_NzNLYDb9CZ|Drawing circuits with proper symbols|Science|Energy|10|11|0.026
mt_vFT_GbkP9m|More batteries, brighter bulb|Science|Energy|10|11|0.026
mt_-QY08-88rw|Why circuit components behave differently|Science|Energy|10|11|0.026
mt_2bnXrfS4Iq|Current, voltage, and what they measure|Science|Energy|11|12|0.026
mt_68pIoiiG4g|Energy can't be created or destroyed|Science|Energy|11|12|0.053
mt_Jvg_r4yWaY|Energy stores and transfers|Science|Energy|11|12|0.057
mt_2_YoprauaJ|Static electricity and sparks|Science|Energy|11|12|0.022
mt_ySnOkVIu22|Conduction, convection, and radiation|Science|Energy|12|13|0.059
mt_JyfLtl_nhw|Efficiency, Sankey diagrams, and work done|Science|Energy|12|13|0.186
mt_DI1cyAyGyN|Heating experiments and Q = mcΔT|Science|Energy|12|13|0.186
mt_H3ZDK0EYNV|Ohm's Law: voltage, current, resistance|Science|Energy|12|13|0.022
mt_ckpA3oZQ44|Power: watts and energy per second|Science|Energy|12|13|0.049
mt_w2A8D76ymp|Renewable vs non-renewable energy|Science|Energy|12|14|0.212
mt_loEMaQ8kFA|Series vs parallel circuits|Science|Energy|12|13|0.022
mt_GBY8enpzO0|Forces Vocabulary|Science|Forces & Motion|5|8|0.036
mt_B3W5EfimJw|Pushes & Pulls|Science|Forces & Motion|5|6|0.051
mt_RlILL2sccX|Testing Push & Pull Designs|Science|Forces & Motion|5|6|0.003
mt_lcf8lx-LkZ|Contact & Non-Contact Forces|Science|Forces & Motion|7|8|0.036
mt_k7GOtslF-x|Drawing Force Diagrams|Science|Forces & Motion|7|12|0.051
mt_-p_xp4hMvh|Friction & Surfaces|Science|Forces & Motion|7|8|0.038
mt_9NvuqZKNiV|Magnetic Materials|Science|Forces & Motion|7|8|0.012
mt_jgNB2752b9|Magnetic Poles|Science|Forces & Motion|7|9|0.012
mt_3WMADSy0mA|Balanced & Unbalanced Forces|Science|Forces & Motion|8|9|0.025
mt_AlLYwCm92a|Predicting Motion Patterns|Science|Forces & Motion|8|9|0.265
mt_Y9k86G8BBT|Air Resistance & Friction|Science|Forces & Motion|9|10|0.014
mt_F3ATPTCYm6|Force & Motion Vocabulary|Science|Forces & Motion|9|11|0.012
mt_AvrQauS_zX|Gravity & Falling Objects|Science|Forces & Motion|9|11|0.025
mt_Q2k3fSwyzQ|Levers, Pulleys & Gears|Science|Forces & Motion|9|10|0.014
mt_OUv-QXmW7_|Reading Distance-Time Graphs|Science|Forces & Motion|10|13|0.261
mt_56aspHjU19|Magnetic Fields|Science|Forces & Motion|11|12|0.012
mt_sUVeVXzRuq|Mass vs Weight|Science|Forces & Motion|11|12|0.021
mt_-OndzpVsrv|Relative Motion|Science|Forces & Motion|11|12|0.26
mt_AiWlJfvC3O|Resultant Forces|Science|Forces & Motion|11|12|0.018
mt_q-1a86ydgU|Speed & Distance-Time Graphs|Science|Forces & Motion|11|12|0.26
mt_fkwcCB5px7|Deformation & Fluid Pressure|Science|Forces & Motion|12|13|0.01
mt_2qkn8Lhc8e|Electromagnets|Science|Forces & Motion|12|13|0.033
mt_xkn2sf93WJ|Investigating Forces|Science|Forces & Motion|12|13|0.019
mt_vuNjYx3qOy|Moments, Pressure & Hooke's Law|Science|Forces & Motion|12|14|0.015
mt_tXxxCFl32J|Newton's First & Second Laws|Science|Forces & Motion|12|13|0.018
mt_fbYbe3YSVj|Newton's Third Law|Science|Forces & Motion|12|13|0.016
mt__7BVYUN180|Motors & the Motor Effect|Science|Forces & Motion|13|14|0.033
mt_LTb0ZReMR2|Caring for minibeasts|Science|Insects & Minibeasts|5|7|0.005
mt_Wr6DDgr_kH|Caterpillar to butterfly|Science|Insects & Minibeasts|5|7|0.008
mt_yR1moI5kX1|Common minibeasts: naming and recognising|Science|Insects & Minibeasts|5|7|0.141
mt__7hXSTbu9s|How minibeasts move|Science|Insects & Minibeasts|5|7|0.038
mt_zir5yyAzUB|Minibeast Habitats|Science|Insects & Minibeasts|5|7|0.123
mt_QH-Fs97twT|Minibeasts in the food chain|Science|Insects & Minibeasts|5|7|0.098
mt_BI6oGIO-xM|What is a minibeast?|Science|Insects & Minibeasts|5|7|0.146
mt_SZJ1mN7Vfk|Bees and pollination|Science|Insects & Minibeasts|7|9|0.012
mt_07Geg7LITa|Camouflage, warning colours, and mimicry|Science|Insects & Minibeasts|7|9|0.008
mt_M7YrfAZk8u|Incredible insects: record-breakers|Science|Insects & Minibeasts|7|9|0.007
mt_hsN-YvCNQY|Insect life cycles: complete metamorphosis|Science|Insects & Minibeasts|7|9|0.008
mt_4vHa3I5bNj|Not all minibeasts are insects|Science|Insects & Minibeasts|7|9|0.025
mt_guaaD6Dn2M|Social insects: ants and bees|Science|Insects & Minibeasts|7|9|0.014
mt__bhJX2SuFJ|Sorting and Identifying Minibeasts|Science|Insects & Minibeasts|7|9|0.018
mt_oNWXXAn3cn|The insect body plan|Science|Insects & Minibeasts|7|9|0.038
mt_7_XXh9NCp0|Insect Adaptations|Science|Insects & Minibeasts|9|11|0.011
mt_Oz8yNPNtub|Insect anatomy in depth|Science|Insects & Minibeasts|9|11|0.007
mt_a9VnPBhoYs|Insect communication and behaviour|Science|Insects & Minibeasts|9|11|0.008
mt_r6oKXpN0er|Insects in ecosystems|Science|Insects & Minibeasts|9|11|0.051
mt_5_Zr9xXDNH|The most successful animals on Earth|Science|Insects & Minibeasts|9|11|0.051
mt__EL7DHjf5R|Threats to insects and conservation|Science|Insects & Minibeasts|9|11|0.051
mt_ShAptVcQR3|Types of Metamorphosis|Science|Insects & Minibeasts|9|11|0.008
mt_auVZZEuXjs|Describing Material Properties|Science|Matter & Materials|5|6|0.138
mt_SwaNNdm_Ks|Grouping Materials|Science|Matter & Materials|5|6|0.123
mt_ZAJvTcroFO|Naming Everyday Materials|Science|Matter & Materials|5|6|0.137
mt_5r47Pvstyn|Objects vs Materials|Science|Matter & Materials|5|6|0.138
mt_1JFUNQDwAJ|States of Matter Vocabulary|Science|Matter & Materials|5|7|0.186
mt_wf-SJhZ1kC|Changing Shapes of Solids|Science|Matter & Materials|6|7|0.042
mt_rTn43s8RNX|Choosing the Right Material|Science|Matter & Materials|6|8|0.027
mt_ahSqW_kK1b|Changes & Separation Vocabulary|Science|Matter & Materials|7|9|0.022
mt_zHnOGwHIEz|Classifying Materials|Science|Matter & Materials|7|8|0.007
mt_htAYR-iCFF|Drawing Particle Diagrams|Science|Matter & Materials|7|11|0.108
mt_Pl-nsjYGZ3|Heating & Cooling Changes|Science|Matter & Materials|7|9|0.109
mt_GQpqoR5YOc|Taking Apart & Rebuilding|Science|Matter & Materials|7|8|0.001
mt_e3-_toGuWf|Testing Materials for Uses|Science|Matter & Materials|7|10|0.021
mt_Qkewo5M3_c|Evaporation & the Water Cycle|Science|Matter & Materials|8|9|0.04
mt_YQkUdIHO8L|Solids, Liquids & Gases|Science|Matter & Materials|8|9|0.047
mt_Ge4Wtg6QMM|Advanced Material Properties|Science|Matter & Materials|9|11|0.034
mt_Mf-T-fYRLX|Dissolving & Solutions|Science|Matter & Materials|9|10|0.051
mt_rbPioPELM1|Irreversible Changes|Science|Matter & Materials|9|11|0.047
mt_MVovx37Xct|Material Properties Vocabulary|Science|Matter & Materials|9|11|0.022
mt_UKmtuAsSLN|Reversible Changes|Science|Matter & Materials|9|10|0.047
mt_2b6CB0w3Yx|Separating Mixtures|Science|Matter & Materials|9|10|0.037
mt_ehC1wsdmUz|Conservation of Mass|Science|Matter & Materials|10|11|0.048
mt_ylruY6VhOf|Matter Is Made of Particles|Science|Matter & Materials|10|11|0.04
mt_Z_Wu_77ybI|Atoms, Elements & Compounds|Science|Matter & Materials|11|12|0.036
mt_CyV7crZ8hl|How Materials Change State|Science|Matter & Materials|11|12|0.016
mt_Sc_SorJhXW|Metals vs Non-Metals|Science|Matter & Materials|11|13|0.026
mt_1hgck6ucII|Physical vs Chemical Changes|Science|Matter & Materials|11|13|0.051
mt_MBTVB-E-S7|Pure Substances & Mixtures|Science|Matter & Materials|11|13|0.041
mt_U_tJvy3cbB|Separating Mixtures|Science|Matter & Materials|11|13|0.042
mt_b6kZgqolEd|The Particle Model|Science|Matter & Materials|11|12|0.038
mt_wfEfQuHOG-|The Periodic Table|Science|Matter & Materials|11|12|0.026
mt_QKRYLwaOU8|Acid Reactions & Salts|Science|Matter & Materials|12|13|0.105
mt_AN2kJE6I0s|Acids, Alkalis & pH|Science|Matter & Materials|12|13|0.081
mt_mTpV-0rtkO|Earth's Atmosphere & CO2|Science|Matter & Materials|12|14|0.208
mt_0e5rZxbAeR|Finite Resources & Recycling|Science|Matter & Materials|12|14|0.233
mt_UoqUPI_uNz|Reactions That Release or Absorb Heat|Science|Matter & Materials|12|13|0.082
mt_zsYW61cn_q|The Reactivity Series|Science|Matter & Materials|12|14|0.051
mt_NckKLZ3uCE|The Rock Cycle|Science|Matter & Materials|12|14|0.059
mt_v0K6GRi4ZL|Types of Chemical Reaction|Science|Matter & Materials|12|13|0.053
mt_w83U-_noVR|Ceramics, Polymers & Composites|Science|Matter & Materials|13|14|0.019
mt_4bJiGiMPmy|Coasts & Beaches|Science|Ocean Life|5|7|0.064
mt_ytUG3yjCYt|Ocean Animal Variety|Science|Ocean Life|5|7|0.124
mt_l6OpmOKMuT|Ocean Food Chains|Science|Ocean Life|5|7|0.1
mt_w2u9bXP9n7|Rock Pool Habitats|Science|Ocean Life|5|7|0.027
mt_mRCPP_Ab2W|Whales & Dolphins Are Mammals|Science|Ocean Life|5|7|0.083
mt_oAg79ju344|What Is the Ocean?|Science|Ocean Life|5|7|0.141
mt_m31_gPS8F1|What Ocean Animals Need|Science|Ocean Life|5|7|0.135
mt__aHSZTm5k5|Classifying Ocean Animals|Science|Ocean Life|7|9|0.083
mt_AxGPeVRm__|Coral Reefs|Science|Ocean Life|7|9|0.016
mt_9EoS35vaYB|Ocean Animal Adaptations|Science|Ocean Life|7|9|0.052
mt_sQpIV0-qY7|Ocean Depth Zones|Science|Ocean Life|7|9|0.062
mt_OnV_DTp5i8|Ocean Food Webs|Science|Ocean Life|7|9|0.075
mt_8QOeG3CuKc|The Five Oceans|Science|Ocean Life|7|9|0.06
mt_yxL1v4LuqR|The Ocean Floor|Science|Ocean Life|7|9|0.018
mt_kCSy3Lsgme|Tides, Waves & Currents|Science|Ocean Life|7|9|0.049
mt_dRCnJEIwk4|Deep-Sea Creatures|Science|Ocean Life|9|11|0.021
mt_1m5ItPiwUK|Exploring the Ocean|Science|Ocean Life|9|11|0.011
mt_Te-ulgYMUd|Ocean Animal Migrations|Science|Ocean Life|9|11|0.037
mt_w4OYcWJs6H|Ocean Ecosystems|Science|Ocean Life|9|11|0.089
mt_J6uccv2Bo4|Ocean Pollution & Harm|Science|Ocean Life|9|11|0.056
mt_KRNU0IOKfO|Oceans & Climate|Science|Ocean Life|9|11|0.105
mt_50SdpkNH49|Protecting the Ocean|Science|Ocean Life|9|11|0.074
mt_6Wx--Du8j3|Deep-Sea Life Without Sunlight|Science|Ocean Life|11|13|0.018
mt_Mp_CpVK6e-|Ocean Currents and Global Heat|Science|Ocean Life|11|12|0.066
mt_EXO1bJ3G_v|Coral Bleaching & Acidification|Science|Ocean Life|12|13|0.068
mt_NPTjGJIyb3|Predator Loss and Ecosystem Effects|Science|Ocean Life|12|14|0.047
mt_kKxbPHi5Db|Deep-Ocean Exploration Technology|Science|Ocean Life|13|14|0.048
mt_fDoE-pL6Jv|Animal Body Groups|Science|Organisms & Life Processes|5|7|0.059
mt_83gRQ9OPkc|Body Parts & Senses|Science|Organisms & Life Processes|5|6|0.038
mt_j7cer_Nmor|Common Plants & Trees|Science|Organisms & Life Processes|5|6|0.19
mt_13CtLTcWUB|Herbivores, Carnivores & Omnivores|Science|Organisms & Life Processes|5|6|0.13
mt_zexbopQjG0|Living Things Vocabulary|Science|Organisms & Life Processes|5|7|0.185
mt_zVLOm6U7bh|Naming Common Animals|Science|Organisms & Life Processes|5|6|0.22
mt_xT6jPzyj92|Parts of a Plant|Science|Organisms & Life Processes|5|6|0.062
mt_L1469gt34A|What Living Things Need|Science|Organisms & Life Processes|5|7|0.171
mt_oR6dwRj2Ll|Animal Life Stages|Science|Organisms & Life Processes|6|7|0.059
mt_cEzX5r7kp0|Offspring resemble parents|Science|Organisms & Life Processes|6|11|0.012
mt_0B64gfJf7j|Seeds & Plant Growth|Science|Organisms & Life Processes|6|7|0.057
mt_3v0VNkwquK|What Plants Need to Grow|Science|Organisms & Life Processes|6|8|0.019
mt_1J5fwxNDxL|Animal Classification Vocabulary|Science|Organisms & Life Processes|7|9|0.055
mt_E1wR8IfCV6|Animal Nutrition|Science|Organisms & Life Processes|7|8|0.056
mt_7EqhgErJyU|Drawing Life Cycle Diagrams|Science|Organisms & Life Processes|7|8|0.055
mt_6xsEXxKdUX|How Plant Parts Work|Science|Organisms & Life Processes|7|8|0.062
mt_4IVWRAZoNC|Life Cycles of Organisms|Science|Organisms & Life Processes|7|9|0.071
mt_WNBHZ1d94L|Pollination & Seed Dispersal|Science|Organisms & Life Processes|7|8|0.06
mt_g4YSiOCS8g|Skeletons & Muscles|Science|Organisms & Life Processes|7|8|0.022
mt_GF6L7J4MNN|Water Transport in Plants|Science|Organisms & Life Processes|7|8|0.015
mt_lutxvMlkwS|What Plants Need to Thrive|Science|Organisms & Life Processes|7|8|0.019
mt_LRzjbo1Fn6|How animals adapt to environments|Science|Organisms & Life Processes|8|11|0.119
mt_h4abSktujo|Inheritance Vocabulary|Science|Organisms & Life Processes|8|10|0.044
mt_1wxwg782yX|Inherited characteristics|Science|Organisms & Life Processes|8|9|0.044
mt_Ruk2-lyGPZ|The Digestive System|Science|Organisms & Life Processes|8|9|0.025
mt_Tls5qJ4p0L|Traits: inherited and environmental|Science|Organisms & Life Processes|8|9|0.003
mt_DbXWivdJFB|Types of Teeth|Science|Organisms & Life Processes|8|9|0.016
mt_UR5LvBeyF1|Variation & Survival Advantage|Science|Organisms & Life Processes|8|9|0.063
mt_OSfCeIeBak|Human Life Stages|Science|Organisms & Life Processes|9|10|0.03
mt_K8DJzqbksM|Organ Systems Vocabulary|Science|Organisms & Life Processes|9|11|0.011
mt_IzlVK0Eony|Senses, Brain & Responses|Science|Organisms & Life Processes|9|10|0.018
mt_8VA40Tumth|Structures for Survival|Science|Organisms & Life Processes|9|10|0.018
mt_2x-EwdBsgl|Diet, Exercise & Lifestyle|Science|Organisms & Life Processes|10|11|0.036
mt_PYPs2yD2sn|Energy from Food & the Sun|Science|Organisms & Life Processes|10|11|0.025
mt_lWqmKn5Jvr|Evolution vocabulary|Science|Organisms & Life Processes|10|11|0.041
mt_YSyjTZfjvv|Nutrient Transport in Animals|Science|Organisms & Life Processes|10|11|0.027
mt_3-ii06P4YS|Plants Grow from Air & Water|Science|Organisms & Life Processes|10|11|0.022
mt_BX4D8cCFtQ|The Circulatory System|Science|Organisms & Life Processes|10|11|0.031
mt_83KkBCtVyR|Calculating Dietary Energy|Science|Organisms & Life Processes|11|13|0.01
mt_7hB8s5eOP1|Cells to Organ Systems|Science|Organisms & Life Processes|11|12|0.027
mt_VfA4xo4kUv|Cells Under the Microscope|Science|Organisms & Life Processes|11|12|0.049
mt_NZHFcEtTyI|Diet Imbalance & Deficiency|Science|Organisms & Life Processes|11|13|0.01
mt_0NlbulkB5P|Digestion & Enzymes|Science|Organisms & Life Processes|11|13|0.025
mt_yefw2CQT4x|Joints, Tendons & Ligaments|Science|Organisms & Life Processes|11|13|0.015
mt_lm0usBAF53|Muscles Work in Pairs|Science|Organisms & Life Processes|11|13|0.015
mt_sDmrVCfzqt|Nutrients in a Healthy Diet|Science|Organisms & Life Processes|11|13|0.015
mt_bABr-c2DfV|Parts of Plant and Animal Cells|Science|Organisms & Life Processes|11|12|0.033
mt_zM5vu31jgl|Photosynthesis|Science|Organisms & Life Processes|11|12|0.03
mt_fhqBH9scsU|Plant Cells vs Animal Cells|Science|Organisms & Life Processes|11|12|0.029
mt_g9RcQOhU5d|Single-Celled Organisms|Science|Organisms & Life Processes|11|12|0.004
mt_Qkl46lyris|The Human Skeleton|Science|Organisms & Life Processes|11|13|0.015
mt_lMLeNLDRO8|Using a Microscope|Science|Organisms & Life Processes|11|12|0.001
mt_mquPi2IP-J|Aerobic Respiration|Science|Organisms & Life Processes|12|13|0.018
mt_TKZefYXaVS|Anaerobic Respiration|Science|Organisms & Life Processes|12|14|0.01
mt_zaXr5wcJD2|Body Temperature Regulation|Science|Organisms & Life Processes|12|14|0.01
mt_V9SQS9gLFw|Gas Exchange & Breathing|Science|Organisms & Life Processes|12|13|0.019
mt_fCvmdI6xGO|Gut Bacteria & Digestion|Science|Organisms & Life Processes|12|13|0.023
mt_TR2oTy9c2M|Heart Structure & Double Circulation|Science|Organisms & Life Processes|12|13|0.036
mt_i80I-1MLP2|How Diffusion Works|Science|Organisms & Life Processes|12|13|0.016
mt_tQkCzRcWG7|Human Reproduction|Science|Organisms & Life Processes|12|13|0.01
mt_1VIE8FlZvL|Pathogens & the Immune System|Science|Organisms & Life Processes|12|14|0.007
mt_ck57CDFGet|Plant Reproduction|Science|Organisms & Life Processes|12|13|0.011
mt_2R3xRpYhMa|Effects of Drugs & Alcohol|Science|Organisms & Life Processes|13|14|0.044
mt_aO018DkCun|Arctic vs Antarctic|Science|Polar Regions|5|7|0.059
mt_22XbXTRq50|Brave Polar Explorers|Science|Polar Regions|5|7|0.007
mt_SrmHaJXKrX|Ice & Snow|Science|Polar Regions|5|7|0.012
mt_3duNkf6Qmr|Midnight Sun & Polar Night|Science|Polar Regions|5|7|0.004
mt_CK2orHetl3|Penguins|Science|Polar Regions|5|7|0.057
mt_7OJjLOl0fz|Polar Animals|Science|Polar Regions|5|7|0.059
mt_O9dH94NFae|Polar Bears|Science|Polar Regions|5|7|0.057
mt_4uPnLieBPN|Where Are the Poles?|Science|Polar Regions|5|7|0.152
mt_kDKo4lxRKi|Cold-Weather Adaptations|Science|Polar Regions|7|9|0.008
mt_z9jn9HogfE|Comparing Arctic & Antarctic|Science|Polar Regions|7|9|0.019
mt_scbDHJZZHK|Ice & States of Matter|Science|Polar Regions|7|9|0.012
mt_rqalOvjkj3|Inuit & Sami Peoples|Science|Polar Regions|7|9|0.01
mt_7nduoLvoB1|Polar Food Chains|Science|Polar Regions|7|9|0.014
mt_X4CJpPRxae|The Arctic Tundra|Science|Polar Regions|7|9|0.012
mt_islVn_P28Z|The Race to the South Pole|Science|Polar Regions|7|9|0.014
mt_f9syMry-0S|Why Polar Seasons Are Extreme|Science|Polar Regions|7|9|0.007
mt_itldWmVItr|Antarctic Treaty & Research|Science|Polar Regions|9|11|0.014
mt_Fqna9qHffr|Climate Change at the Poles|Science|Polar Regions|9|11|0.107
mt_cMmG8VLbAp|Earth's Frozen Water|Science|Polar Regions|9|11|0.079
mt_5_kErPeeNu|Glaciers & Ice Sheets|Science|Polar Regions|9|11|0.008
mt_GbZFuGDFsa|Polar Climate Zone|Science|Polar Regions|9|11|0.042
mt_7QeiS95TRC|Polar Conservation & Future|Science|Polar Regions|9|11|0.112
mt_kOYw43NPzr|Polar Ecosystems Compared|Science|Polar Regions|9|11|0.012
mt_I_c57p0aGN|Polar Exploration Then & Now|Science|Polar Regions|9|11|0.012
mt_g1qgxmlJQ2|Polar Oceans and World Climate|Science|Polar Regions|9|11|0.075
mt_s08-QxASd2|Everyday Foods from Rainforests|Science|Rainforests|5|7|0.003
mt_2zJ1NrGgYm|Indigenous Rainforest Peoples|Science|Rainforests|5|7|0.005
mt_ntxlccnYzB|Inside a Rainforest|Science|Rainforests|5|7|0.001
mt_xVW5U41tbp|Rainforest Animals|Science|Rainforests|5|7|0.116
mt_XL2gqdKJfu|Rainforest Insects|Science|Rainforests|5|7|0.005
mt_-0cjwyYhce|Rainforest Layers|Science|Rainforests|5|7|0.122
mt_x5ZrQMAZ5v|Rainforest Plants|Science|Rainforests|5|7|0.056
mt_FZ_ixwU1p1|What Is a Rainforest?|Science|Rainforests|5|7|0.148
mt_0u3QNroZ34|Where Rainforests Are|Science|Rainforests|5|7|0.015
mt_OtShuvs3x8|Classifying Rainforest Organisms|Science|Rainforests|7|9|0.03
mt_m43jiOAOCt|Indigenous Ecological Knowledge|Science|Rainforests|7|9|0.005
mt_XxgU_91AXg|Rainforest Animal Survival Tricks|Science|Rainforests|7|9|0.004
mt_1LFVPjdGg-|Rainforest Food Webs|Science|Rainforests|7|9|0.033
mt_Wx5m6mwkpj|Rainforest Plant Adaptations|Science|Rainforests|7|9|0.005
mt_ZWTk6eP1qF|Rainforest Water Cycle|Science|Rainforests|7|9|0.03
mt_38d-k-dJPa|The Amazon Rainforest|Science|Rainforests|7|9|0.021
mt_v6CBCMuvz1|Tropical Rainforest Climate|Science|Rainforests|7|9|0.023
mt_2OSTHTWDpa|Deforestation Causes & Scale|Science|Rainforests|9|11|0.055
mt_JcfP1hWKa_|Nutrient Cycling in Thin Soil|Science|Rainforests|9|11|0.008
mt_pPGaf8bR8r|Rainforest Biodiversity|Science|Rainforests|9|11|0.026
mt_kON8bYEHYl|Rainforest Conservation|Science|Rainforests|9|11|0.055
mt_ZM7u9m-gS4|Rainforest Futures & Trade-Offs|Science|Rainforests|9|11|0.107
mt_xE_b3JiDZU|Rainforest Products in Daily Life|Science|Rainforests|9|11|0.052
mt_HJd-8EEC6N|Rainforests & Global Climate|Science|Rainforests|9|11|0.103
mt_hbDflQfW-U|Temperate Rainforests|Science|Rainforests|9|11|0.034
mt_XirhnAB6Ye|Asking scientific questions|Science|Scientific Inquiry|5|8|0.057
mt_nNYo5A-7Bl|Comparing Design Solutions|Science|Scientific Inquiry|5|8|0.036
mt_hi8cVycbwn|Modelling with Sketches|Science|Scientific Inquiry|5|8|0.033
mt_vJO5Bxk4z-|Observing with simple equipment|Science|Scientific Inquiry|5|7|0.055
mt_ZFwPZaDJ0_|Recording Data|Science|Scientific Inquiry|5|7|0.049
mt_Wa44s-f8Ws|Simple tests and experiments|Science|Scientific Inquiry|5|7|0.051
mt_obF-6VYRya|Changing Your Mind with Evidence|Science|Scientific Inquiry|6|8|0.037
mt_Hw70LI5xza|Observation vs Interpretation|Science|Scientific Inquiry|6|7|0.056
mt_7IFpDVNsmt|Classifying living things|Science|Scientific Inquiry|7|9|0.057
mt_QrVF5n7vci|Could there be another explanation?|Science|Scientific Inquiry|7|9|0.063
mt_7VrR1GzhrN|Drawing conclusions from evidence|Science|Scientific Inquiry|7|9|0.103
mt_qgb76wHN2X|Fair testing|Science|Scientific Inquiry|7|9|0.04
mt_nUnowllzaN|Measuring accurately|Science|Scientific Inquiry|7|9|0.047
mt_CVywzrjT_c|Using evidence to answer questions|Science|Scientific Inquiry|7|9|0.116
mt_HveO1bOXpJ|Comparing Possible Solutions|Science|Scientific Inquiry|8|11|0.036
mt_X0Tr8IYaEd|Correlation vs Causation|Science|Scientific Inquiry|8|10|0.052
mt_eoPcc4nrBE|Fair testing (age 8+)|Science|Scientific Inquiry|8|11|0.036
mt_Z5-fSCOBep|Simple Design Problems|Science|Scientific Inquiry|8|11|0.036
mt_Psun-u_lPf|Accurate Measurement|Science|Scientific Inquiry|9|11|0.023
mt_rDjtmDogJr|Classifying living things (age 9+)|Science|Scientific Inquiry|9|11|0.047
mt_ArVBEpMAPk|Controlling variables|Science|Scientific Inquiry|9|11|0.152
mt_nyPMkeHlVJ|Drawing conclusions from evidence (age 9+)|Science|Scientific Inquiry|9|11|0.164
mt_AstzvYDU2m|Evidence Supporting Ideas|Science|Scientific Inquiry|9|11|0.201
mt_5PgQB0QkWi|Fair testing (age 9+)|Science|Scientific Inquiry|9|11|0.152
mt_1GVAmcwAiO|Science Can Be Revised|Science|Scientific Inquiry|9|11|0.053
mt_Ae56umVlTT|Controlling variables (age 11+)|Science|Scientific Inquiry|11|12|0.146
mt_auJqTemMpI|Repeated tests for reliability|Science|Scientific Inquiry|11|12|0.023
mt_3jmBpEepYX|Drawing conclusions from evidence (age 12+)|Science|Scientific Inquiry|12|13|0.228
mt_YHsUhi4Prc|Tables, charts, and graphs|Science|Scientific Inquiry|12|13|0.044
mt_ThTbUuNb3p|Writing Science Reports|Science|Scientific Inquiry|13|14|0.265
mt_ByXgbTld6R|Moon Phases|Science|Space Exploration|5|7|0.01
mt_XlyF294bPR|Our Solar System|Science|Space Exploration|5|7|0.051
mt_BVpB5wyijZ|Spotting Constellations|Science|Space Exploration|5|7|0.01
mt_PiWZA8Z0ZJ|Sun, Moon & Stars|Science|Space Exploration|5|7|0.053
mt_oiqsIP97V3|What Astronauts Do|Science|Space Exploration|5|7|0.014
mt_uoTBeyMhGm|Asteroids, Comets & Dwarf Planets|Science|Space Exploration|7|9|0.012
mt_w2xiMNkyyX|Earth's Spin & Orbit|Science|Space Exploration|7|9|0.026
mt_-SZU6cVB_-|How Telescopes Work|Science|Space Exploration|7|9|0.011
mt_W8Eq3CqWJf|Planet Features|Science|Space Exploration|7|9|0.016
mt_7GwWplh-48|Space Robots & Rovers|Science|Space Exploration|7|9|0.018
mt_AVk2EmSULC|The Eight Planets|Science|Space Exploration|7|9|0.022
mt_15FduGRf5c|The Moon's Orbit|Science|Space Exploration|7|9|0.016
mt_u3Y3Tb-G_n|The Sun is a star|Science|Space Exploration|7|9|0.049
mt_KiRn5lnRgj|Changing Ideas About Space|Science|Space Exploration|9|11|0.015
mt_Y2WcY2lOTK|Gravity Pulls Things Down|Science|Space Exploration|9|11|0.019
mt_iTjrKEdAOj|Life Cycle of Stars|Science|Space Exploration|9|11|0.014
mt_TlGhXAqC4p|Scale of the Solar System|Science|Space Exploration|9|11|0.014
mt_9VZem2vUqk|Seasonal Constellations|Science|Space Exploration|9|11|0.016
mt_H9RAGGiHBL|Space Exploration Milestones|Science|Space Exploration|9|11|0.018
mt_aulwq39aj8|The Vast Scale of Space|Science|Space Exploration|9|11|0.015
mt_ae-cHHFR76|Why the Sun Looks Brightest|Science|Space Exploration|9|11|0.023
mt_UjuriPLVgT|Finding Exoplanets|Science|Space Exploration|11|13|0.018
mt_rbY77m8_s1|Observing with Light Waves|Science|Space Exploration|11|13|0.015
mt_1nl396BaVa|Orbital Mechanics|Science|Space Exploration|12|13|0.033
mt_KYx0m4OyZv|Where Elements Come From|Science|Space Exploration|12|14|0.03
mt_EIbltgXRWR|Journey to Mars|Science|Space Exploration|13|14|0.04
mt_EHuU1ZeUFA|Naming the Planets|Science|Space Systems & Earth's History|5|8|0.055
mt_K0mZxY2AM8|Why seasons change|Science|Space Systems & Earth's History|5|7|0.059
mt_fk33IEGP-T|Sun, Moon, and stars|Science|Space Systems & Earth's History|6|7|0.026
mt_ZJu8s-Q1xa|Rapid earth changes|Science|Space Systems & Earth's History|7|8|0.023
mt_LQt4vnKeB4|Earth & Space Vocabulary|Science|Space Systems & Earth's History|8|11|0.01
mt_q15w--Fb5H|Earth's rotation and day/night|Science|Space Systems & Earth's History|9|11|0.023
mt_GheLsWvrJ4|How fossils form|Science|Space Systems & Earth's History|9|10|0.025
mt_5l7iGkf1Tp|The solar system|Science|Space Systems & Earth's History|9|10|0.026
mt_tMLsTPQHwF|Shadows|Science|Space Systems & Earth's History|10|11|0.031
mt_ZhKuYCbXz1|Star Brightness & Distance|Science|Space Systems & Earth's History|10|11|0.019
mt_4V-vYhFUcm|Phases of the Moon|Science|Space Systems & Earth's History|11|12|0.021
mt_33RrpbceZE|The solar system (age 11+)|Science|Space Systems & Earth's History|11|12|0.019
mt_lFiDFPkVmH|Why We Have Seasons|Science|Space Systems & Earth's History|11|12|0.022
mt_v9uYnIY5-B|Galaxies and the universe|Science|Space Systems & Earth's History|12|13|0.034
mt_oLjz18CxDg|Universal Gravitation|Science|Space Systems & Earth's History|12|13|0.027
mt_lHasFmgvnT|Life Cycle of a Star|Science|Space Systems & Earth's History|13|14|0.033
mt_cxJRc15osy|Basic Body Needs|Science|The Human Body|5|7|0.023
mt_SdIWVjzopp|Bones & Muscles|Science|The Human Body|5|7|0.021
mt_tiPyEkm4cU|How Breathing Works|Science|The Human Body|5|7|0.033
mt_pJ5zsocdNx|The Brain Controls the Body|Science|The Human Body|5|7|0.026
mt_nwSWPTENmv|The Five Senses|Science|The Human Body|5|7|0.011
mt_lp1eTsQen7|The Heart & Blood|Science|The Human Body|5|7|0.033
mt_QhLAeAlHI0|Balanced Diet & Food Groups|Science|The Human Body|7|9|0.019
mt_C7FNeIDGc6|Cells, Tissues & Organs|Science|The Human Body|7|9|0.022
mt_6N-4TqCleR|How Muscles Move Bones|Science|The Human Body|7|9|0.003
mt_-gkJdxJUQT|How the Eye Works|Science|The Human Body|7|9|0.011
mt_OMmiuv9ZLH|Naming Major Bones|Science|The Human Body|7|9|0.003
mt_JpQUM1129q|The Digestive Journey|Science|The Human Body|7|9|0.018
mt_I047mKeeaq|Types of Teeth|Science|The Human Body|7|9|0.007
mt_QK-ZZb7UUN|Circulation & Breathing Together|Science|The Human Body|9|11|0.012
mt_pu2mmK27UA|Growing Up & Puberty|Science|The Human Body|9|11|0.038
mt_4k3HGahK2k|Healthy Lifestyle Choices|Science|The Human Body|9|11|0.025
mt_g_M4Vh_pK7|Heart & Blood Circulation|Science|The Human Body|9|11|0.015
mt_zPDDJLAl-J|How the Lungs Work|Science|The Human Body|9|11|0.011
mt_4JpMXUIxeD|The Immune System|Science|The Human Body|9|11|0.011
mt_qzbgwaUQOA|The Nervous System|Science|The Human Body|9|11|0.012
mt_LkOMijDvL7|Immunity & Vaccines|Science|The Human Body|11|13|0.007
mt_okUMpHsV-P|Neurons & Brain Structure|Science|The Human Body|11|13|0.012
mt_0sELh0MYWb|DNA & Genes|Science|The Human Body|12|14|0.005
mt_J40cOn7VWn|How the Body Stays in Balance|Science|The Human Body|12|14|0.049
mt_roinupb_7L|Cancer & Stem Cells|Science|The Human Body|13|14|0.005
mt_uUa6cgv8zV|Earth Is Made of Rock|Science|Volcanoes & Earthquakes|5|7|0.027
mt__pMF-Xb0TE|Earthquake Safety|Science|Volcanoes & Earthquakes|5|7|0.001
mt_adpdEaKEBC|Fast & Slow Earth Changes|Science|Volcanoes & Earthquakes|5|7|0.027
mt_BLQ2_OXPod|Power of Eruptions|Science|Volcanoes & Earthquakes|5|7|0.019
mt_e29VrLfmYt|What Is an Earthquake|Science|Volcanoes & Earthquakes|5|7|0.03
mt_S9SKah-yi_|What Is a Volcano|Science|Volcanoes & Earthquakes|5|7|0.047
mt_dSeFrAWE4v|Active, Dormant & Extinct|Science|Volcanoes & Earthquakes|7|9|0.012
mt_jwElFY7Syd|Earth's Layers|Science|Volcanoes & Earthquakes|7|9|0.029
mt_QtIAWOcoQT|Inside a Volcano|Science|Volcanoes & Earthquakes|7|9|0.015
mt_XG4RqUIXm8|Pompeii & Vesuvius|Science|Volcanoes & Earthquakes|7|9|0.012
mt_bhwf_rDXQL|Ring of Fire|Science|Volcanoes & Earthquakes|7|9|0.034
mt_Wu-ftkzoiE|Tsunamis|Science|Volcanoes & Earthquakes|7|9|0.011
mt_NYA50DFcOO|Types of Rock|Science|Volcanoes & Earthquakes|7|9|0.019
mt_NVr4AhsvIq|Why Earthquakes Happen|Science|Volcanoes & Earthquakes|7|9|0.027
mt_yDZbQODIwp|Earthquake-Resistant Design|Science|Volcanoes & Earthquakes|9|11|0.086
mt_W4j7T_PnGH|Eruption Types & Volcano Shape|Science|Volcanoes & Earthquakes|9|11|0.055
mt_rML9unnd9x|Famous Eruptions & Pangaea|Science|Volcanoes & Earthquakes|9|11|0.056
mt_mdZ3nBWChW|Measuring Earthquake Strength|Science|Volcanoes & Earthquakes|9|11|0.026
mt_ZRoQVXf_aD|Monitoring Volcanoes|Science|Volcanoes & Earthquakes|9|11|0.051
mt_cpDpjJaE5u|Natural Disaster Solutions|Science|Volcanoes & Earthquakes|9|10|0.052
mt_-JnOhdei6F|Plate Boundaries|Science|Volcanoes & Earthquakes|9|11|0.057
mt_XrvPx5kUfO|Tectonic Plates|Science|Volcanoes & Earthquakes|9|11|0.057
mt_z7AJZapsJj|The Rock Cycle|Science|Volcanoes & Earthquakes|9|11|0.025
mt_gv_uoHkdjR|How Tectonic Plates Move|Science|Volcanoes & Earthquakes|11|12|0.057
mt__kFxuAgs6d|Seismic Waves & Earth's Interior|Science|Volcanoes & Earthquakes|11|13|0.022
mt_edaoZRkK6M|Hazard Assessment & Evacuation|Science|Volcanoes & Earthquakes|12|14|0.086
mt_Am_iTzHjoe|Supervolcanoes & Volcanic Winter|Science|Volcanoes & Earthquakes|12|13|0.09
mt_QwWo6an9N1|Volcanoes & Mass Extinctions|Science|Volcanoes & Earthquakes|13|14|0.088
mt_ZL9qVVnpwN|Communication with Light & Sound|Science|Waves, Light & Sound|6|7|0.078
mt_4i-FKXDDXh|Light & Seeing in the Dark|Science|Waves, Light & Sound|6|8|0.092
mt_YPSx5pbpVl|Light & Sound Vocabulary|Science|Waves, Light & Sound|6|8|0.092
mt_p6frRFuxS6|Transparent, Translucent & Opaque|Science|Waves, Light & Sound|6|7|0.021
mt_VBl1T1sFCM|Vibrations & Sound|Science|Waves, Light & Sound|6|9|0.078
mt_Oru08pKlxd|How Shadows Form|Science|Waves, Light & Sound|7|8|0.021
mt_3yuqKww2tU|Protecting Eyes from Sunlight|Science|Waves, Light & Sound|7|8|0.003
mt_gLy3ZgZWiN|Reflecting Light|Science|Waves, Light & Sound|7|8|0.012
mt_KTSoXcO7OL|Pitch of Sounds|Science|Waves, Light & Sound|8|9|0.005
mt_Pau0aqLNgp|Sound Fading with Distance|Science|Waves, Light & Sound|8|9|0.007
mt_ydtcIBwHB9|Sound Travels Through Materials|Science|Waves, Light & Sound|8|9|0.015
mt__00ZSLnB7p|Volume & Vibrations|Science|Waves, Light & Sound|8|9|0.014
mt_6w2g7aoPgz|How We See Objects|Science|Waves, Light & Sound|9|11|0.022
mt_n5_Jt4ExUd|Patterns & Codes for Information|Science|Waves, Light & Sound|9|10|0.011
mt_SFOSbVnrJ8|Wave Behaviour Vocabulary|Science|Waves, Light & Sound|9|11|0.015
mt_ph4xZVMiVq|Waves & How They Move|Science|Waves, Light & Sound|9|10|0.016
mt_qZro923zvz|Light Travels in Straight Lines|Science|Waves, Light & Sound|10|11|0.022
mt_DQk9oDE7gr|How Sound Waves Travel|Science|Waves, Light & Sound|11|12|0.012
mt_PifbJOuXrG|Reflection & Refraction|Science|Waves, Light & Sound|11|12|0.051
mt_LxK9OKZQZX|Wave Properties & Types|Science|Waves, Light & Sound|11|12|0.015
mt_qzGADV-NGe|White Light & Colour|Science|Waves, Light & Sound|11|12|0.048
mt_-2VNlwAR5z|Drawing Ray Diagrams|Science|Waves, Light & Sound|12|13|0.034
mt_FVERuBoCD1|Ray Diagrams & Images|Science|Waves, Light & Sound|12|13|0.048
mt_XSp-S0wter|The Electromagnetic Spectrum|Science|Waves, Light & Sound|12|13|0.07
mt_w5HzPpOUmj|Waves & Different Materials|Science|Waves, Light & Sound|12|13|0.07
mt_Dj2xr8CoI0|Dressing for the Weather|Science|Weather & Climate|5|7|0.003
mt_TlLE4cZgOr|Rain & Puddles|Science|Weather & Climate|5|7|0.083
mt_fI-8iqf_Id|Seasons & Weather Patterns|Science|Weather & Climate|5|7|0.108
mt_4pLvMN8uzL|Storm Safety|Science|Weather & Climate|5|7|0.007
mt_PrWc-HZzDl|Temperature & Thermometers|Science|Weather & Climate|5|7|0.082
mt_jc9k_HJQGd|Types of Weather|Science|Weather & Climate|5|7|0.133
mt_URezjbU-6f|Weather Forecasting & Safety|Science|Weather & Climate|5|6|0.016
mt_j7cj9eWN7w|What Is Wind?|Science|Weather & Climate|5|7|0.062
mt_IhWzO4sQPg|Cloud Types|Science|Weather & Climate|7|9|0.083
mt_hjJkBWruO6|Geography & Local Weather|Science|Weather & Climate|7|9|0.094
mt_fhqVdj4BYr|The Water Cycle|Science|Weather & Climate|7|9|0.092
mt_BO_AHGLCk0|Thunder & Lightning|Science|Weather & Climate|7|9|0.01
mt_sA0RvWXSYY|Using Weather Instruments|Science|Weather & Climate|7|9|0.012
mt_AghN5YcCHX|Weather Forecasting|Science|Weather & Climate|7|9|0.016
mt_AB-TEMXSGJ|Weather vs Climate|Science|Weather & Climate|7|9|0.085
mt_-UAxilUtUt|What Causes Wind|Science|Weather & Climate|7|9|0.057
mt_JmMtZCifJB|Designing for Weather Hazards|Science|Weather & Climate|8|9|0.04
mt_DbI1kNg_0R|Climate Change Basics|Science|Weather & Climate|9|11|0.12
mt_TMOzMCE17H|Climate Zones|Science|Weather & Climate|9|11|0.075
mt_6EfevRyeFW|Extreme Weather Events|Science|Weather & Climate|9|11|0.026
mt_VI5kdtf28e|Natural resources|Science|Weather & Climate|9|10|0.079
mt_3pgTpuetKi|Reading Weather Maps|Science|Weather & Climate|9|11|0.038
mt_-YYnLLIZh5|Sun-Driven Weather Systems|Science|Weather & Climate|9|11|0.077
mt_fkcxpeYP85|The Atmosphere|Science|Weather & Climate|9|11|0.037
mt_iiUdDUEEGY|Weather-Resistant Engineering|Science|Weather & Climate|9|11|0.055
mt_iYOcfzFqMw|Global Wind Patterns|Science|Weather & Climate|11|13|0.047
mt_EQQWKz03P8|Greenhouse Gas Science|Science|Weather & Climate|11|12|0.045
mt__wWHVvqMWb|Hurricanes, Tornadoes & Monsoons|Science|Weather & Climate|12|13|0.097
mt_olFzbawexJ|Reading Ancient Climate Records|Science|Weather & Climate|12|14|0.093
mt_Wzj1RETm9A|Net Zero & Energy Transition|Science|Weather & Climate|13|14|0.213
"""

    /// `topicId>prerequisiteId`, one dependency per row.
    private static let edgeTable = """
mt__00ZSLnB7p>mt_VBl1T1sFCM
mt__00ZSLnB7p>mt_YPSx5pbpVl
mt_02DH7sGXCi>mt_H7DquwQi_F
mt_02DH7sGXCi>mt_WBfj79OqXz
mt_07Geg7LITa>mt_oNWXXAn3cn
mt_09sySPqM9Z>mt_ndGqFPWyen
mt_0ajzcoKAKw>mt_M7XhBBzYof
mt_0ajzcoKAKw>mt_NDZYiLvApW
mt_0ajzcoKAKw>mt_oB-L8EVdIP
mt_0ajzcoKAKw>mt_PYPs2yD2sn
mt_0ajzcoKAKw>mt_w4OYcWJs6H
mt_0B64gfJf7j>mt_L1469gt34A
mt_-0cjwyYhce>mt_FZ_ixwU1p1
mt_0e5rZxbAeR>mt_mTpV-0rtkO
mt_0e5rZxbAeR>mt_zsYW61cn_q
mt_0ewYhTSHtP>mt_0VOZSVjo6c
mt_0ewYhTSHtP>mt_cJjnPjuvCU
mt_0FYFiLTqx4>mt_2DBPJ38iWl
mt_0FYFiLTqx4>mt_M_xcaRcvSo
mt_0_K-GrKQpd>mt_wUSbRt3-qw
mt_0MfpLj0Uhb>mt_mLPEMpYb_R
mt_0MfpLj0Uhb>mt_v5yDTWEiyQ
mt_0MfpLj0Uhb>mt_yHQacItlhf
mt_0NlbulkB5P>mt_7hB8s5eOP1
mt_0NlbulkB5P>mt_Ruk2-lyGPZ
mt_0NlbulkB5P>mt_sDmrVCfzqt
mt_0QJoKWABdC>mt_ntqNLHsj5n
mt_0QJoKWABdC>mt_uorNrPTh6U
mt_0Rx1ISxXFE>mt_HPf-dVtA3p
mt_0Rx1ISxXFE>mt_udgPy5oAvR
mt_0sELh0MYWb>mt_6aJUzBYGNs
mt_0T0Zf0YG6k>mt_AstzvYDU2m
mt_0T0Zf0YG6k>mt_JBWMqZVO7S
mt_0T0Zf0YG6k>mt_M8UQTURODF
mt_0T0Zf0YG6k>mt_oH1XC8aQYn
mt_0T0Zf0YG6k>mt_QHKqckBdAk
mt_0T0Zf0YG6k>mt_T8JGTJ-oNI
mt_0u3QNroZ34>mt_FZ_ixwU1p1
mt_0u4KLbvBa1>mt_LpSuPgL31x
mt_0u4KLbvBa1>mt_nvdpxAJTBG
mt_0VOZSVjo6c>mt_Amw5ikSSQI
mt_0VOZSVjo6c>mt_j8Pv3s7TZR
mt_0Wg5F97osg>mt_FHIAv6dfhU
mt_0Wg5F97osg>mt_gxCIASSezX
mt_0wUwxyBs5y>mt_0QJoKWABdC
mt_0wUwxyBs5y>mt_ntqNLHsj5n
mt_0XxyaQLRhn>mt_fR0UtsSREU
mt_0XxyaQLRhn>mt_-hTTat0mBR
mt_0XxyaQLRhn>mt__N55B7u7HD
mt_0zqOTjjW2k>mt_v3Vz_Pgjjv
mt_0zqOTjjW2k>mt_V_wIdRZLsG
mt_13CtLTcWUB>mt_zVLOm6U7bh
mt_14F_x1Xwwp>mt_CSGqz245rV
mt_14OR-MhGJ9>mt_YKkCM63fSC
mt_14T5yPXUq_>mt_b7T-CjOYUR
mt_14T5yPXUq_>mt_o_p-3tCxiM
mt_14T5yPXUq_>mt_-V7EnqU7gG
mt_15FduGRf5c>mt_ByXgbTld6R
mt_15FduGRf5c>mt_w2xiMNkyyX
mt_167X6Ax8P7>mt_Jf8xcX4UTq
mt_167X6Ax8P7>mt_WtIFJSCQIT
mt_18fK9sQdIz>mt_DyGBW3ZHh3
mt_18fK9sQdIz>mt_K5jM7vlVhA
mt_18qkgxr_-T>mt_yBJyCfhtem
mt_19j_5AuuQI>mt_9L3NQqgqRd
mt_19j_5AuuQI>mt_cChv2j_-Da
mt_19qy2uuaKp>mt_mMMXD4v9Sh
mt_19qy2uuaKp>mt_P0HBNfp46z
mt_1badik7iKJ>mt_2OtRUM_0zW
mt_1badik7iKJ>mt_ATYLKt0je-
mt_1badik7iKJ>mt_FspV_imUGK
mt_1badik7iKJ>mt_tpT9brpI6D
mt_1dXhJp6qLJ>mt_1VSFoM44JU
mt_1dXhJp6qLJ>mt_DJh2JPwTf6
mt_1GF5MeNZPA>mt_sUVOS2jH3J
mt_1GF5MeNZPA>mt_wGxq92Na5g
mt_1GVAmcwAiO>mt_QrVF5n7vci
mt_1GVAmcwAiO>mt_v5yDTWEiyQ
mt_1GVAmcwAiO>mt_X0Tr8IYaEd
mt_1hgck6ucII>mt_b6kZgqolEd
mt_1hgck6ucII>mt_ehC1wsdmUz
mt_1hgck6ucII>mt_rbPioPELM1
mt_1hgck6ucII>mt_UKmtuAsSLN
mt_1hgck6ucII>mt_Z_Wu_77ybI
mt_1KkvzwYxbR>mt_vXRzMbiPff
mt_1LFVPjdGg->mt_x5ZrQMAZ5v
mt_1LFVPjdGg->mt_xVW5U41tbp
mt_1m5ItPiwUK>mt_dRCnJEIwk4
mt_1m5ItPiwUK>mt_yxL1v4LuqR
mt_1MLi55bPnt>mt_2Um22lTBZV
mt_1nl396BaVa>mt_oLjz18CxDg
mt_1nl396BaVa>mt_Y2WcY2lOTK
mt_-1okUh0Jdv>mt_oVwNnjYPUY
mt_1PAWhRhpdg>mt_4Km38F4L-6
mt_1PAWhRhpdg>mt_AabJisinfi
mt_1PAWhRhpdg>mt_ifPDOYvUqm
mt_1ro8W1cZYn>mt_86DyHo9zO3
mt_1VIE8FlZvL>mt_7hB8s5eOP1
mt_1VIE8FlZvL>mt_g9RcQOhU5d
mt_1VmTUxBrNd>mt_3qrCtdoVAU
mt_1VmTUxBrNd>mt_J03RFlVdas
mt_1VSfm9yiLn>mt_f8n4txtLej
mt_1VSfm9yiLn>mt_ylXdiVRAYv
mt_1VSFoM44JU>mt_bKlnc7dyVK
mt_1VSFoM44JU>mt_iycQEai3dK
mt_1wxwg782yX>mt_h4abSktujo
mt_1YwOCMMwD8>mt_XfyqXLqzpx
mt_1z-gJBJFlM>mt__BbOjiY5A5
mt_1z-gJBJFlM>mt_cVp_nop-5L
mt_20WfHhnL39>mt_yqAL6O5i_v
mt_22XbXTRq50>mt_4uPnLieBPN
mt_26OJ9MetR9>mt_PThM5P7Umd
mt_26OJ9MetR9>mt_X5fdB4haHf
mt_2agkUcdah9>mt_hi8cVycbwn
mt_2agkUcdah9>mt_iGSfQg3g5c
mt_2b6CB0w3Yx>mt_ahSqW_kK1b
mt_2b6CB0w3Yx>mt_Mf-T-fYRLX
mt_2b6CB0w3Yx>mt_YQkUdIHO8L
mt_2bnXrfS4Iq>mt_NzCNuABT3E
mt_2bnXrfS4Iq>mt_NzNLYDb9CZ
mt_2bnXrfS4Iq>mt_vFT_GbkP9m
mt_2DBPJ38iWl>mt_M_xcaRcvSo
mt_2DBPJ38iWl>mt_oN7fI4d_kU
mt_2ESZh70NyS>mt_89riIKwGYp
mt_2ESZh70NyS>mt_a3dov8CZkq
mt_2ESZh70NyS>mt_SXbZ3bC9z7
mt_2ESZh70NyS>mt_TDUpy57QVM
mt_2GDBmKCJxs>mt_9REmUc8r4D
mt_2GDBmKCJxs>mt_GLY3R3YSlf
mt_2GDBmKCJxs>mt_VXcua6-txq
mt_2GDBmKCJxs>mt_wvcFlwOrDl
mt_2jbUekyTu4>mt_fZTn0W_iZR
mt_2jbUekyTu4>mt_IzQvs7k_sE
mt_2jbUekyTu4>mt_wQ89AEXhz3
mt_2l06snztdP>mt_RioBUxHz1X
mt_2l06snztdP>mt_yBJyCfhtem
mt_2NfIKEYdbm>mt_9yFAtUkoYr
mt_2NfIKEYdbm>mt_sZXPK1FnRB
mt_2NfIKEYdbm>mt_u7Jxjjatkh
mt_2NKzPeLzIm>mt_PThM5P7Umd
mt_2OSTHTWDpa>mt_38d-k-dJPa
mt_2OSTHTWDpa>mt_pPGaf8bR8r
mt_2OSTHTWDpa>mt_Wyd-l-6H7G
mt_2oswCNuapH>mt_a6AYrbb7x4
mt_2oswCNuapH>mt_S7UTAhptLi
mt_2OtRUM_0zW>mt_eiB3-6pu6a
mt_2OtRUM_0zW>mt_ePXg_XyCKU
mt_2OtRUM_0zW>mt_ESgc4YBw-a
mt_2OtRUM_0zW>mt_h0gJcSuwdL
mt_2OtRUM_0zW>mt_liIW336odh
mt_2qkn8Lhc8e>mt_2bnXrfS4Iq
mt_2qkn8Lhc8e>mt_56aspHjU19
mt_2R3xRpYhMa>mt_0NlbulkB5P
mt_2R3xRpYhMa>mt_2x-EwdBsgl
mt_2uHYdoxD0H>mt_q7zxOloj_L
mt_2uHYdoxD0H>mt_v5yDTWEiyQ
mt_2Um22lTBZV>mt_akBotspaf2
mt_2Um22lTBZV>mt_B3W5EfimJw
mt_-2VNlwAR5z>mt_4MFUAsbx_6
mt_2VpdPjvewx>mt_wPgpMJ0-PA
mt_2VpdPjvewx>mt_Zks8xyInSG
mt_2VR963szuk>mt_yGv8doDAmp
mt_2X9Cd38eSJ>mt_tHtjfjjFrl
mt_2XDGT5tei1>mt__N55B7u7HD
mt_2x-EwdBsgl>mt_4k3HGahK2k
mt_2x-EwdBsgl>mt_BX4D8cCFtQ
mt_2x-EwdBsgl>mt_E1wR8IfCV6
mt_2yas4Unc8o>mt_d8al9JcajP
mt_2yas4Unc8o>mt_IL86kadLSS
mt_2_YoprauaJ>mt_2bnXrfS4Iq
mt_2_YoprauaJ>mt_d-EKO-pKkP
mt_2zJ1NrGgYm>mt_FZ_ixwU1p1
mt_32B7xjUPwF>mt_LE7nFEwS12
mt_33RrpbceZE>mt_5l7iGkf1Tp
mt_33RrpbceZE>mt_EHuU1ZeUFA
mt_33zncDHC3N>mt_Ag9NSWJu-X
mt_33zncDHC3N>mt_QxsoqVUt6u
mt_33zncDHC3N>mt_rqLMfiw61L
mt_33zncDHC3N>mt_sXRHr7tfS5
mt_35-DhMh_Yr>mt_i1kk9HDctI
mt_35-DhMh_Yr>mt_Iwg2diBSyW
mt_35-DhMh_Yr>mt_MOY_2Cqalz
mt_35-DhMh_Yr>mt_pAuo9Op89t
mt_37QCuGOxFe>mt_EqXlZfB4jp
mt_37QCuGOxFe>mt_p_jxNLdus4
mt_37QCuGOxFe>mt_YKkCM63fSC
mt_38d-k-dJPa>mt_0u3QNroZ34
mt_38d-k-dJPa>mt_v6CBCMuvz1
mt_3duNkf6Qmr>mt_4uPnLieBPN
mt_3e_PQxwC12>mt_m1W6nTQJ2b
mt_3e_PQxwC12>mt_THl9GLxwoL
mt_3fwYu7imd4>mt_t0g2SlP404
mt_3fwYu7imd4>mt_Zt30Gxi-qp
mt_3-ii06P4YS>mt_GF6L7J4MNN
mt_3-ii06P4YS>mt_lutxvMlkwS
mt_3JgrHY221M>mt_ehGS_uVSJv
mt_3JgrHY221M>mt_oIzycTBeE4
mt_3jmBpEepYX>mt_99G6Msdzw-
mt_3jmBpEepYX>mt_AstzvYDU2m
mt_3jmBpEepYX>mt__kFxuAgs6d
mt_3jmBpEepYX>mt_nyPMkeHlVJ
mt_3jmBpEepYX>mt_YHsUhi4Prc
mt_3jmBpEepYX>mt_ZxdfRbwkKM
mt_3pgTpuetKi>mt_AB-TEMXSGJ
mt_3pgTpuetKi>mt_AghN5YcCHX
mt_3pgTpuetKi>mt_NYsz6QgaaE
mt_3pgTpuetKi>mt_sA0RvWXSYY
mt_3qrCtdoVAU>mt_QhFEDyIwSO
mt_3qrCtdoVAU>mt_vHzVa3SURC
mt_3qrCtdoVAU>mt_VUQNveSYjQ
mt_3rTIyJDw7->mt_h3vmvQW5Wa
mt_3rTIyJDw7->mt_i9rJbuFO3p
mt_3rTIyJDw7->mt_xfwv0M83mJ
mt_3rTIyJDw7->mt_xq3YHZ2zeR
mt_3S10OOGPqu>mt_h0CVtqI2xo
mt_3S10OOGPqu>mt_MFfYcnv6Tv
mt_3tPI0HqqcN>mt_p6MhZJYYPN
mt_3tPI0HqqcN>mt_SoDP1fSQEB
mt_3tQXH9GwIa>mt_bjlY5TE1y-
mt_3tQXH9GwIa>mt_LuwHnQItF_
mt_3tz3Otap5j>mt_cChv2j_-Da
mt_-3udyo6VyB>mt_3qrCtdoVAU
mt_-3udyo6VyB>mt_WBdHkc2HTf
mt_3v0VNkwquK>mt_L1469gt34A
mt_3VmBdlAeOZ>mt_AQo4u7O4sM
mt_3VmBdlAeOZ>mt_dXq9VWm31W
mt_3VmBdlAeOZ>mt_TqDq6jyOmL
mt_3WMADSy0mA>mt_B3W5EfimJw
mt_3WMADSy0mA>mt_k7GOtslF-x
mt_3WMADSy0mA>mt_-p_xp4hMvh
mt_3XJkeIn6J6>mt_4m8BimI4G5
mt_3XJkeIn6J6>mt_6XCURuNwPw
mt_3y7xKP9MjU>mt_CBHwluE6Lp
mt_3y7xKP9MjU>mt_k2WE0-22-4
mt_3yuqKww2tU>mt_4i-FKXDDXh
mt_42QD6nYjiZ>mt_ghK1mnEstc
mt_42QD6nYjiZ>mt_VgOePicFYK
mt_44HkROUnzE>mt_5S4byWDX6n
mt_44HkROUnzE>mt_NDZYiLvApW
mt_44HkROUnzE>mt_pWwV_8OgXD
mt_4A4RpX-Go9>mt_mLPEMpYb_R
mt_4A4RpX-Go9>mt_o8ciHks8t2
mt_4A7FYmvVhA>mt_S0hzjAeLSK
mt_4A7FYmvVhA>mt_wwdRhPyz6s
mt_4emC463IyW>mt_3XJkeIn6J6
mt_4emC463IyW>mt_EXlmTURK_o
mt_4i-FKXDDXh>mt_YPSx5pbpVl
mt_4IVWRAZoNC>mt_1J5fwxNDxL
mt_4IVWRAZoNC>mt_7EqhgErJyU
mt_4IVWRAZoNC>mt_oR6dwRj2Ll
mt_4IVWRAZoNC>mt_WNBHZ1d94L
mt_4IxR66uGLc>mt_gR5_n99Ntt
mt_4IxR66uGLc>mt_ujwtRoYJ34
mt_4JpMXUIxeD>mt_C7FNeIDGc6
mt_4K1dr204Hi>mt_4Km38F4L-6
mt_4K1dr204Hi>mt_4ubP_RMg9o
mt_4K1dr204Hi>mt_W17Kbwm0-u
mt_4K1dr204Hi>mt_ZM9mhHsyYZ
mt_4k3HGahK2k>mt_4JpMXUIxeD
mt_4k3HGahK2k>mt_QhLAeAlHI0
mt_4k3HGahK2k>mt_QK-ZZb7UUN
mt_4Km38F4L-6>mt_TgHxujL81r
mt_4Km38F4L-6>mt_WsM4EmdOLe
mt_4lp_b5Pzik>mt_zkFbMLpu3U
mt_4m8BimI4G5>mt_HNOPGJYiRK
mt_4MFUAsbx_6>mt_e4V6hvcuEJ
mt_4MFUAsbx_6>mt_qUGMyMYn9m
mt_4PA9IrxtCQ>mt_sJyZW4qYUG
mt_4PA9IrxtCQ>mt_y8sicbhMci
mt_4pLvMN8uzL>mt_jc9k_HJQGd
mt_4ubP_RMg9o>mt_DRlbMok2lT
mt_4ubP_RMg9o>mt_ZM9mhHsyYZ
mt_4-vfMgmCVB>mt_9yFAtUkoYr
mt_4-vfMgmCVB>mt_AvJMWQbDsr
mt_4vHa3I5bNj>mt_oNWXXAn3cn
mt_4V-vYhFUcm>mt_5l7iGkf1Tp
mt_4V-vYhFUcm>mt_LQt4vnKeB4
mt_4V-vYhFUcm>mt_q15w--Fb5H
mt_4WaKWECpcv>mt_8jFSnXxqQD
mt_50SdpkNH49>mt_AxGPeVRm__
mt_50SdpkNH49>mt_J6uccv2Bo4
mt_50SdpkNH49>mt_KRNU0IOKfO
mt_56aspHjU19>mt_jgNB2752b9
mt_5FREdVoS8s>mt_j32D5DZX7x
mt_5HV4mbgSGH>mt_mFJ-2ZF6Tk
mt_5HV4mbgSGH>mt_Vi4Vo5xs_g
mt_5HV4mbgSGH>mt_Zks8xyInSG
mt_5_kErPeeNu>mt_scbDHJZZHK
mt_5l7iGkf1Tp>mt_EHuU1ZeUFA
mt_5l7iGkf1Tp>mt_fk33IEGP-T
mt_5mIcmKRCgA>mt_ATYLKt0je-
mt_5mIcmKRCgA>mt_FspV_imUGK
mt_5mIcmKRCgA>mt_nOCPx5qw0Z
mt_5mIcmKRCgA>mt_WBdHkc2HTf
mt_5mIcmKRCgA>mt_yK51ZnKA8m
mt_5n-O41lUgn>mt_LE7nFEwS12
mt_5n-O41lUgn>mt_mLPEMpYb_R
mt_5n-O41lUgn>mt_scBgiMKhG_
mt_5NwqN6pf_A>mt_NLSfvB9vUl
mt_5NwqN6pf_A>mt_QqG6IdmTSE
mt_5OxKnrGEMP>mt_bEvMBUv4eG
mt_5OxKnrGEMP>mt_lSFwVU7V9g
mt_5OxKnrGEMP>mt_V_kAitNbLN
mt_5PgQB0QkWi>mt_7VrR1GzhrN
mt_5PgQB0QkWi>mt_ArVBEpMAPk
mt_5PgQB0QkWi>mt_hbe_kdE_7C
mt_5qNMVZi3dQ>mt_NnlnxCx1DO
mt_5qNMVZi3dQ>mt_PCX1jZZnf9
mt_5S4byWDX6n>mt_DbI1kNg_0R
mt_5S4byWDX6n>mt_DCelLx_H1A
mt_5S4byWDX6n>mt_EaWjCyn8W2
mt_5S4byWDX6n>mt_v3Vz_Pgjjv
mt_5S4byWDX6n>mt_Wyd-l-6H7G
mt_5TBUFnCy5->mt_JH_6RpNWjr
mt_5TBUFnCy5->mt_nTL-owFJTF
mt_5XLhiqmocP>mt_DkzsZdyaL2
mt_5XLhiqmocP>mt_oqvJJKCJXw
mt_5XLhiqmocP>mt_VA126P6Wp5
mt_5_Zr9xXDNH>mt_4vHa3I5bNj
mt_5_Zr9xXDNH>mt_r6oKXpN0er
mt_68pIoiiG4g>mt_akBotspaf2
mt_68pIoiiG4g>mt_Jvg_r4yWaY
mt_69hFD2NgGe>mt_H4YZ1rSKP3
mt_69hFD2NgGe>mt_klyw-tdlhP
mt_6aJUzBYGNs>mt_VfA4xo4kUv
mt_6EfevRyeFW>mt_BO_AHGLCk0
mt_6EfevRyeFW>mt_fhqVdj4BYr
mt_6EfevRyeFW>mt_-UAxilUtUt
mt_6eTZUwKQZr>mt_kJ5wYzO8qC
mt_6eTZUwKQZr>mt_LE7nFEwS12
mt_6-j1NO2ZUH>mt_U4cIBXVug4
mt_6-j1NO2ZUH>mt_Zdv-b-iW5K
mt_6J1wmCWf41>mt_AF2BeFQwfX
mt_6J1wmCWf41>mt_zuKAX6lcYR
mt_6lHBTwQPrS>mt_mB7DVai-Uf
mt_6N-4TqCleR>mt_OMmiuv9ZLH
mt_6N-4TqCleR>mt_SdIWVjzopp
mt_6nqVnVdexe>mt_MlD0gwLSw9
mt_6_O6THdEDK>mt_6J1wmCWf41
mt_6_O6THdEDK>mt_pbuhUQJjtt
mt_6oxQPNLHNv>mt_BFJ-ch_8QU
mt_6oxQPNLHNv>mt_DOe893F6gN
mt_6w2g7aoPgz>mt_gLy3ZgZWiN
mt_6w2g7aoPgz>mt_Oru08pKlxd
mt_6w2g7aoPgz>mt_SFOSbVnrJ8
mt_6W5zzDIGZH>mt_frDIaXzWbx
mt_6W5zzDIGZH>mt_ZhUuT__i2H
mt_6Wx--Du8j3>mt_dRCnJEIwk4
mt_6XCURuNwPw>mt__N55B7u7HD
mt_6XCURuNwPw>mt_TcG90kS8nu
mt_6xj94tmpi->mt_CVywzrjT_c
mt_6xj94tmpi->mt_dlm3NspUyy
mt_6xj94tmpi->mt_h_shhH-6DC
mt_6xj94tmpi->mt_RhntJz7p_6
mt_6XnezHOcM3>mt_26OJ9MetR9
mt_6XnezHOcM3>mt_X5fdB4haHf
mt_6xNmQLzuqm>mt_e4x3l2JeLI
mt_6xsEXxKdUX>mt_xT6jPzyj92
mt_6Z42wJaKYG>mt_fKwgN61ttR
mt_6Z42wJaKYG>mt_lWqmKn5Jvr
mt_6Z42wJaKYG>mt_mwirOvigWD
mt_6Z42wJaKYG>mt_r8XnXwRA6g
mt_6Z42wJaKYG>mt_Sa48W7KXB5
mt_70qDTI14td>mt_o_p-3tCxiM
mt_70qDTI14td>mt_VgOePicFYK
mt_70Ys4i1AB1>mt__KHQttMde3
mt_70Ys4i1AB1>mt_UvNrOXny1i
mt_76SPWvdI7r>mt_9IzhGUZ30z
mt_76SPWvdI7r>mt_x8TshvbbQT
mt__7BVYUN180>mt_2qkn8Lhc8e
mt_7D-vlii8F->mt_enj1sMcfOT
mt_7D-vlii8F->mt_Of-WsrRQ8B
mt_7D-vlii8F->mt_u7Jxjjatkh
mt_7e-lG7YOWa>mt_deexfCHU9m
mt_7e-lG7YOWa>mt_VI5kdtf28e
mt_7e-lG7YOWa>mt_YB0qF5KX9C
mt_7EqhgErJyU>mt_xppl18avyY
mt_7GwWplh-48>mt_oiqsIP97V3
mt_7GwWplh-48>mt_W8Eq3CqWJf
mt_7hB8s5eOP1>mt_fhqBH9scsU
mt__7hXSTbu9s>mt_yR1moI5kX1
mt_7IFpDVNsmt>mt_c29FaCTNsx
mt_7IFpDVNsmt>mt_nUnowllzaN
mt_7IFpDVNsmt>mt_ZFwPZaDJ0_
mt_7nduoLvoB1>mt_7OJjLOl0fz
mt_7nduoLvoB1>mt_CK2orHetl3
mt_7OJjLOl0fz>mt_aO018DkCun
mt_7OJjLOl0fz>mt_CK2orHetl3
mt_7OJjLOl0fz>mt_O9dH94NFae
mt_7oZ2YenzhX>mt_N8CpN1EJrP
mt_7oZ2YenzhX>mt_wq-1OJ_8s5
mt_7QeiS95TRC>mt_Fqna9qHffr
mt_7QeiS95TRC>mt_itldWmVItr
mt_7QeiS95TRC>mt_rqalOvjkj3
mt_7rJM8eWUfw>mt_IzQvs7k_sE
mt_7SfQuXgNtd>mt_0QJoKWABdC
mt_7SfQuXgNtd>mt_EbiGRVK8uR
mt_7SfQuXgNtd>mt_uorNrPTh6U
mt_7SfQuXgNtd>mt_VY3rBq8RyP
mt_7SsduPB2tP>mt_9gpUHWVKMR
mt_7SsduPB2tP>mt_pOstrrS763
mt_7SsduPB2tP>mt_r1hw-KenpK
mt_7VrR1GzhrN>mt_6eTZUwKQZr
mt_7VrR1GzhrN>mt_7IFpDVNsmt
mt_7VrR1GzhrN>mt_lIs10UMkPG
mt_7VrR1GzhrN>mt_qgb76wHN2X
mt_7XcCG43ZZW>mt_OvyoRo47K-
mt_7_XXh9NCp0>mt_07Geg7LITa
mt_7_XXh9NCp0>mt_ShAptVcQR3
mt_83gRQ9OPkc>mt_fDoE-pL6Jv
mt_83KkBCtVyR>mt_sDmrVCfzqt
mt_86DyHo9zO3>mt_4A7FYmvVhA
mt_86DyHo9zO3>mt_NP101Zl-4g
mt_89riIKwGYp>mt_4MFUAsbx_6
mt_89riIKwGYp>mt_e4V6hvcuEJ
mt_89riIKwGYp>mt_oqziWKry-L
mt_8A3pZNOp7Z>mt_pjfmCMMPjO
mt_8ad4U6msea>mt_CSGqz245rV
mt_8atyuvPUZc>mt_fmm-P17Vka
mt_8atyuvPUZc>mt_hVpGOEz2kG
mt_8atyuvPUZc>mt_WBdHkc2HTf
mt_8atyuvPUZc>mt_XSXnTQoQ4l
mt_8bIXVKTdtK>mt_yBJyCfhtem
mt_8_BxtNDrLZ>mt_3jmBpEepYX
mt_8_BxtNDrLZ>mt_bHbpLW1HUg
mt_8_BxtNDrLZ>mt_cSPtyLF3q1
mt_8FwtdJzeDh>mt_w4wKFP3jud
mt_8gy7uxRlF6>mt_r0VXbfAmsH
mt_8gy7uxRlF6>mt_THl9GLxwoL
mt_8H2kO4k2B9>mt_Xt1cRqaBOW
mt_8H2kO4k2B9>mt_YUJ5pwalqL
mt_8jFSnXxqQD>mt_p-nbe0w_lf
mt_8jFSnXxqQD>mt_XLP1IM3Qbb
mt_8OAGVdeTJ_>mt_sBcRdUfAzV
mt_8OAGVdeTJ_>mt_TdV9YGJEoY
mt_8oAzr0WxRb>mt_bjlY5TE1y-
mt_8oAzr0WxRb>mt_PThM5P7Umd
mt_8-POYyg7GJ>mt_sSQlLOnAow
mt_8QOeG3CuKc>mt_nRF_VRntrW
mt_8QOeG3CuKc>mt_oAg79ju344
mt_8qQ2IosZZw>mt_B1ATUEVNPz
mt_8qQ2IosZZw>mt_cJ8CeyRKKs
mt_8qQ2IosZZw>mt_PCX1jZZnf9
mt_8RmpkDxT9L>mt_fR0UtsSREU
mt_8RmpkDxT9L>mt_OvyoRo47K-
mt_8RmpkDxT9L>mt_zuKAX6lcYR
mt_8ShghTx0jd>mt_2DBPJ38iWl
mt_8ShghTx0jd>mt_8ad4U6msea
mt_8ShghTx0jd>mt_bjlY5TE1y-
mt_8StiXnYq1u>mt_33zncDHC3N
mt_8StiXnYq1u>mt_NCrbQe0LdB
mt_8VA40Tumth>mt_6xsEXxKdUX
mt_8VA40Tumth>mt_C7FNeIDGc6
mt_8VA40Tumth>mt_g4YSiOCS8g
mt_8xVHooT4aI>mt_eiB3-6pu6a
mt_8xVHooT4aI>mt_K3R0yaHVcx
mt_8xVHooT4aI>mt_ZOJ6EbdPOb
mt_91f1XFvGZq>mt_o8ciHks8t2
mt_91f1XFvGZq>mt_PJyCGJz5Hv
mt_933BohS9BH>mt_IegHBHERVa
mt_933BohS9BH>mt_kdWoAel3Zl
mt_95zxYqpP7m>mt_klyw-tdlhP
mt_95zxYqpP7m>mt_QR3vxbN1o4
mt_98c2qwEF7Q>mt_aPBzD28_mT
mt_98c2qwEF7Q>mt_izien3ZX51
mt_99G6Msdzw->mt_32B7xjUPwF
mt_99G6Msdzw->mt_wvcFlwOrDl
mt_9EoS35vaYB>mt_m31_gPS8F1
mt_9EoS35vaYB>mt_ytUG3yjCYt
mt_9gpUHWVKMR>mt_aWOK1npO5s
mt_9gpUHWVKMR>mt_phpn6KhCAv
mt_9gpUHWVKMR>mt_SbEaQnMQoD
mt_9hBs430cU4>mt_tHtjfjjFrl
mt_9IzhGUZ30z>mt_fR0UtsSREU
mt_9IzhGUZ30z>mt__KHQttMde3
mt_9IzhGUZ30z>mt_YKkCM63fSC
mt_9k1qcpvVi_>mt_0MfpLj0Uhb
mt_9KmVWCuh5_>mt_bESTSBB0wK
mt_9KmVWCuh5_>mt_CUmjcE7W6c
mt_9KmVWCuh5_>mt_fxPtngwUfz
mt_9L3NQqgqRd>mt_aPBzD28_mT
mt_9L3NQqgqRd>mt_pAcaehday5
mt_9L3NQqgqRd>mt_THl9GLxwoL
mt_9lN0SpKlEH>mt_BLzNxSSdWu
mt_9lN0SpKlEH>mt_v5DyOEpbbr
mt_9NQEiYLQA3>mt_a6AYrbb7x4
mt_9NQEiYLQA3>mt_MOY_2Cqalz
mt_9NQEiYLQA3>mt_wzUzVEBqJb
mt_9NvuqZKNiV>mt_lcf8lx-LkZ
mt_9-OHslmt1g>mt_F978c32kDr
mt_9P9o6d0Qm3>mt_4A7FYmvVhA
mt_9P9o6d0Qm3>mt_AvJMWQbDsr
mt_9P9o6d0Qm3>mt_lIs10UMkPG
mt_9P9o6d0Qm3>mt_nDAcXoPa0c
mt_9P9o6d0Qm3>mt_o8ciHks8t2
mt_9P9o6d0Qm3>mt_PJyCGJz5Hv
mt_9QzSnn8m80>mt_RVK655t391
mt_9REmUc8r4D>mt_LE7nFEwS12
mt_9REmUc8r4D>mt_VXcua6-txq
mt_9VZem2vUqk>mt_BVpB5wyijZ
mt_9VZem2vUqk>mt_w2xiMNkyyX
mt_9XVFje6Tyr>mt_izien3ZX51
mt_9XVFje6Tyr>mt_jY7uf0Cb7o
mt_9Y5-GjF2B0>mt_ggcamLzXAy
mt_9Y96vxG_LH>mt_AabJisinfi
mt_9Y96vxG_LH>mt_ifPDOYvUqm
mt_9yFAtUkoYr>mt_sZXPK1FnRB
mt_A0htaNaK7b>mt_H0ajATAlus
mt_A0htaNaK7b>mt_sMAcZW6vWM
mt_a1FdAsRKOF>mt_Kr3IyA6m-O
mt_a1FdAsRKOF>mt_OvyoRo47K-
mt_A1Xfu5p5KT>mt_1J5fwxNDxL
mt_A1Xfu5p5KT>mt_4IVWRAZoNC
mt_A1Xfu5p5KT>mt_7EqhgErJyU
mt_A1Xfu5p5KT>mt_AylKwhbDWM
mt_A1Xfu5p5KT>mt_ShAptVcQR3
mt_a3dov8CZkq>mt_FP-mjXaq3B
mt_a3dov8CZkq>mt_HnKbuCliNS
mt_a3dov8CZkq>mt_pyMD_SIiYO
mt_a3dov8CZkq>mt_Y6P9y1Rz-u
mt_A4YUbzUFan>mt_-DuXzMVVXQ
mt_a6m7PqTuJN>mt_F978c32kDr
mt_a9VnPBhoYs>mt_guaaD6Dn2M
mt_a9VnPBhoYs>mt_M7YrfAZk8u
mt_AabJisinfi>mt_b7T-CjOYUR
mt_AabJisinfi>mt_TgHxujL81r
mt__ab4knIaSL>mt_SsS7GptD_o
mt_AbnwmKD8oe>mt_9NQEiYLQA3
mt_AbnwmKD8oe>mt_Ag9NSWJu-X
mt_AbnwmKD8oe>mt_iWGnyUyN2j
mt_AbnwmKD8oe>mt_w4nSIDhIgC
mt_AB-TEMXSGJ>mt_fI-8iqf_Id
mt_AB-TEMXSGJ>mt_hjJkBWruO6
mt_AB-TEMXSGJ>mt_jc9k_HJQGd
mt_Ac7oMWhyPw>mt_933BohS9BH
mt_Ac7oMWhyPw>mt_EDgw64OmfA
mt_Ac7oMWhyPw>mt_kdWoAel3Zl
mt_aClzPBiS9k>mt_DVSHx3YMkN
mt_aClzPBiS9k>mt_gR5_n99Ntt
mt_adpdEaKEBC>mt_e29VrLfmYt
mt_adpdEaKEBC>mt_S9SKah-yi_
mt_Ae56umVlTT>mt_ArVBEpMAPk
mt_Ae56umVlTT>mt_QR3vxbN1o4
mt_Ae56umVlTT>mt_WKxX-b86Vr
mt_ae-cHHFR76>mt_u3Y3Tb-G_n
mt_AF2BeFQwfX>mt_OvyoRo47K-
mt_AF2BeFQwfX>mt_pbuhUQJjtt
mt_-af65bxfdp>mt_6oxQPNLHNv
mt_AfIzLRvMgW>mt_-mw3JeIjhU
mt_AfIzLRvMgW>mt_ntqNLHsj5n
mt_AfIzLRvMgW>mt_u1-UfD0rTH
mt_aFvsj35QzC>mt_mLPEMpYb_R
mt_A-FyLLLLzy>mt_w6MxaaoMXZ
mt_AghN5YcCHX>mt_IhWzO4sQPg
mt_AghN5YcCHX>mt_sA0RvWXSYY
mt_AghN5YcCHX>mt_URezjbU-6f
mt_AHAFw-atka>mt_82KKv0Fca3
mt_AHAFw-atka>mt_AvJMWQbDsr
mt_aHAM29nidj>mt_nvdpxAJTBG
mt_AhfyJoTQtY>mt_BhYJZUsErp
mt_AhfyJoTQtY>mt_EqXlZfB4jp
mt_AhfyJoTQtY>mt_Jq0MjURrRC
mt_AhfyJoTQtY>mt_QEr24lqzvH
mt_aHQ9kNt3is>mt_aPBzD28_mT
mt_aHQ9kNt3is>mt_izien3ZX51
mt__aHSZTm5k5>mt_mRCPP_Ab2W
mt__aHSZTm5k5>mt_ytUG3yjCYt
mt_aivrWs6jrS>mt_2jbUekyTu4
mt_aivrWs6jrS>mt_Ep7TDFuYUa
mt_aivrWs6jrS>mt_GzcJEVkNRn
mt_aivrWs6jrS>mt_hbe_kdE_7C
mt_AiWlJfvC3O>mt_B3W5EfimJw
mt_AiWlJfvC3O>mt_F3ATPTCYm6
mt_AiWlJfvC3O>mt_k7GOtslF-x
mt_AiWlJfvC3O>mt_lcf8lx-LkZ
mt_AKAtWEwpcj>mt_mr_Vk7FGzK
mt_AKAtWEwpcj>mt_THl9GLxwoL
mt_ak_ZgoMKRQ>mt_ukLvUD8DFA
mt_AlLYwCm92a>mt_3WMADSy0mA
mt_AlLYwCm92a>mt_OUv-QXmW7_
mt_ALUrJpY0cZ>mt_ATYLKt0je-
mt_ALUrJpY0cZ>mt_PNSyfH56eQ
mt_Am_iTzHjoe>mt_edaoZRkK6M
mt_Am_iTzHjoe>mt__kFxuAgs6d
mt_Am_iTzHjoe>mt_ZRoQVXf_aD
mt_Amw5ikSSQI>mt_aS-Gdh-MHx
mt_Amw5ikSSQI>mt_i1kk9HDctI
mt_Amw5ikSSQI>mt_j8Pv3s7TZR
mt_Amw5ikSSQI>mt_KA5j5OeGvw
mt_AN2kJE6I0s>mt_EXO1bJ3G_v
mt_AN2kJE6I0s>mt_Z_Wu_77ybI
mt_anAe11HAEH>mt_HFRYjTb-Z5
mt_anAe11HAEH>mt_NLSfvB9vUl
mt_anAe11HAEH>mt_yTWxkzzoOZ
mt_aO018DkCun>mt_4uPnLieBPN
mt_aPBzD28_mT>mt_8gy7uxRlF6
mt_aPBzD28_mT>mt_THl9GLxwoL
mt_AQcVRBddko>mt_aPBzD28_mT
mt_AQcVRBddko>mt_U0waNfD8PB
mt_AQo4u7O4sM>mt_GzcJEVkNRn
mt_AR-K72OIIO>mt_18fK9sQdIz
mt_AR-K72OIIO>mt_EmR5n58jZt
mt_AR-K72OIIO>mt_Lb2ZnMdkYR
mt_ArVBEpMAPk>mt_CVywzrjT_c
mt_ArVBEpMAPk>mt_eoPcc4nrBE
mt_ArVBEpMAPk>mt_q7zxOloj_L
mt_ArVBEpMAPk>mt_qgb76wHN2X
mt_ArVBEpMAPk>mt_QR3vxbN1o4
mt_aS-Gdh-MHx>mt_SeNxOZTHCN
mt_asRwlPZXC3>mt_SsS7GptD_o
mt_AstzvYDU2m>mt_1GVAmcwAiO
mt_AstzvYDU2m>mt_nyPMkeHlVJ
mt_AstzvYDU2m>mt_TDUpy57QVM
mt_AstzvYDU2m>mt_ukLvUD8DFA
mt_AstzvYDU2m>mt_X0Tr8IYaEd
mt_auJqTemMpI>mt_Psun-u_lPf
mt_aulwq39aj8>mt_AVk2EmSULC
mt_aulwq39aj8>mt_u3Y3Tb-G_n
mt_auVZZEuXjs>mt_1JFUNQDwAJ
mt_auVZZEuXjs>mt_ZAJvTcroFO
mt_AvJMWQbDsr>mt_lIs10UMkPG
mt_AvJMWQbDsr>mt_nDAcXoPa0c
mt_AvJMWQbDsr>mt_o8ciHks8t2
mt_AVk2EmSULC>mt_u3Y3Tb-G_n
mt_AVk2EmSULC>mt_XlyF294bPR
mt_AvrQauS_zX>mt_3WMADSy0mA
mt_AvrQauS_zX>mt_GBY8enpzO0
mt_AvrQauS_zX>mt_k7GOtslF-x
mt_AvrQauS_zX>mt_lcf8lx-LkZ
mt_av-uRBrhwT>mt_HCweOHWSiu
mt_av-uRBrhwT>mt_HWYAspz-LK
mt_av-uRBrhwT>mt_pis4novXWQ
mt_av-uRBrhwT>mt_TDUpy57QVM
mt_av-uRBrhwT>mt_v5yDTWEiyQ
mt_aVZJhPbc_1>mt_fL1Xz8ostr
mt_aVZJhPbc_1>mt_ZhUuT__i2H
mt_aw0PldeT_L>mt_6-MYToNZ39
mt_aWOK1npO5s>mt_6J1wmCWf41
mt_aWOK1npO5s>mt_AF2BeFQwfX
mt_aWOK1npO5s>mt_FIkqA0qhnj
mt_aWOK1npO5s>mt_RNRymbz5SO
mt__AWSThGJ0d>mt_asRwlPZXC3
mt__AWSThGJ0d>mt__BbOjiY5A5
mt__AWSThGJ0d>mt_oajUvqAiBJ
mt_AxGPeVRm__>mt_m31_gPS8F1
mt_AxGPeVRm__>mt_w2u9bXP9n7
mt_AxGPeVRm__>mt_ytUG3yjCYt
mt_aXNlkbAeIk>mt_N1744276Zu
mt_aXNlkbAeIk>mt_PhIZNl2230
mt_ay0qkGj0jg>mt_enj1sMcfOT
mt_AylKwhbDWM>mt_1J5fwxNDxL
mt_AylKwhbDWM>mt_4vHa3I5bNj
mt_AylKwhbDWM>mt__aHSZTm5k5
mt_AylKwhbDWM>mt_OtShuvs3x8
mt_AylKwhbDWM>mt_ppENoD8vf1
mt_AylKwhbDWM>mt_zVLOm6U7bh
mt_AYzE1EAvI0>mt_ndGqFPWyen
mt_AzTrT5ySCx>mt_u6SYiVx7FX
mt_AzTrT5ySCx>mt_WRRv1ABECC
mt_b0sXYFblDL>mt_cq711F7ruL
mt_b0sXYFblDL>mt_HPf-dVtA3p
mt_b0sXYFblDL>mt_QepALf3bin
mt_b0sXYFblDL>mt_tqgZH11cP5
mt_B1ATUEVNPz>mt_bvxkT1nepy
mt_B1LdSGMP66>mt_0T0Zf0YG6k
mt_B1LdSGMP66>mt_IR8kIjZn_V
mt_B1LdSGMP66>mt_kgTN6yk4oE
mt_B1LdSGMP66>mt_Lu4H4mbsqO
mt_B1LdSGMP66>mt_Qxyikkkzam
mt_B1LdSGMP66>mt_TTzJTF-OkG
mt_B1LdSGMP66>mt_yNGrY9xJ8Y
mt_B1zj1RwQ3a>mt_GRWwTDZ3wD
mt_B1zj1RwQ3a>mt_PZ909yPrEC
mt_B3W5EfimJw>mt_k7GOtslF-x
mt_b4lbTOJYwI>mt_hCVPYlF-7Y
mt_b4lbTOJYwI>mt_SBkTGjiZjZ
mt_b6kZgqolEd>mt_htAYR-iCFF
mt_b6kZgqolEd>mt_ylruY6VhOf
mt_b6kZgqolEd>mt_YQkUdIHO8L
mt_b7T-CjOYUR>mt_ebPelt-qAl
mt_b7T-CjOYUR>mt_FHIAv6dfhU
mt_b7T-CjOYUR>mt_vKcxX6iNOA
mt_B8JOz79O6t>mt_qzwQAOfurw
mt_B8JOz79O6t>mt_wq-1OJ_8s5
mt_B8lX8OCzGu>mt_8VA40Tumth
mt_B8lX8OCzGu>mt_IY3KwGLZgk
mt_bABr-c2DfV>mt_VfA4xo4kUv
mt_bAy4dmP1-A>mt_Qzbh-_v0Gq
mt_bAy4dmP1-A>mt_uSUqTjOl8m
mt_bAYy0ytbfC>mt_M2Gou3O6qT
mt_bAYy0ytbfC>mt_phpn6KhCAv
mt__BbOjiY5A5>mt_bPFToj0OhZ
mt__BbOjiY5A5>mt_K6qtan847r
mt_BdAeZJUOir>mt_8atyuvPUZc
mt_Be1A88GUpu>mt_0ajzcoKAKw
mt_Be1A88GUpu>mt_mquPi2IP-J
mt_Be1A88GUpu>mt_URTJbS3hhs
mt_Be1A88GUpu>mt_zM5vu31jgl
mt_bESTSBB0wK>mt_4MFUAsbx_6
mt_bESTSBB0wK>mt_H6LlpWgEYS
mt_bESTSBB0wK>mt_oqziWKry-L
mt_bESTSBB0wK>mt_PNSyfH56eQ
mt_bESTSBB0wK>mt_u5HkSxZECM
mt_bEvMBUv4eG>mt_E7avIa-tcE
mt_bEvMBUv4eG>mt_P0HBNfp46z
mt_bEvMBUv4eG>mt_szw1Ln490b
mt_bfhng6mOuy>mt_KJeEeTutJI
mt_bfhng6mOuy>mt_yGv8doDAmp
mt_BFJ-ch_8QU>mt_DOe893F6gN
mt_BFJ-ch_8QU>mt_U0waNfD8PB
mt_bHbpLW1HUg>mt_EGIlsfHxb6
mt_bHbpLW1HUg>mt_Z_Wu_77ybI
mt_bhEuF-CCuY>mt_Lu4H4mbsqO
mt_bhEuF-CCuY>mt_ukLvUD8DFA
mt_bhEuF-CCuY>mt_V_kAitNbLN
mt_bhEuF-CCuY>mt_wWlZoLQBR6
mt__bhJX2SuFJ>mt_4vHa3I5bNj
mt_bhwf_rDXQL>mt_adpdEaKEBC
mt_bhwf_rDXQL>mt_e29VrLfmYt
mt_bhwf_rDXQL>mt_KsKLVW_ssY
mt_bhwf_rDXQL>mt_NVr4AhsvIq
mt_bhwf_rDXQL>mt_S9SKah-yi_
mt_BhYJZUsErp>mt_EqXlZfB4jp
mt_BhYJZUsErp>mt_F978c32kDr
mt_BhYJZUsErp>mt_PvU3eoikev
mt_BhYJZUsErp>mt_WBfj79OqXz
mt_bj1YCgNWUx>mt_-vvVxpOHG2
mt_bjlY5TE1y->mt_2DBPJ38iWl
mt_bjlY5TE1y->mt_M_xcaRcvSo
mt_bjlY5TE1y->mt_OiDHqtLoln
mt_bjlY5TE1y->mt_PThM5P7Umd
mt_bK84sPehyP>mt_7OJjLOl0fz
mt_bK84sPehyP>mt_v3Vz_Pgjjv
mt_bK84sPehyP>mt_YynJoQcm_M
mt_bKlnc7dyVK>mt_dpM1l5IOk6
mt_bkMDDstwwG>mt_H8dEMH_wik
mt_bkMDDstwwG>mt_Mb1JUJmnbX
mt_bkMDDstwwG>mt_v5yDTWEiyQ
mt_bKV2JYNwf7>mt_H1pAi4F_Oh
mt_bKV2JYNwf7>mt_mMMXD4v9Sh
mt_bkvB7QYKwg>mt_86DyHo9zO3
mt_bkvB7QYKwg>mt_h3vmvQW5Wa
mt_BLQ2_OXPod>mt_S9SKah-yi_
mt_BLzNxSSdWu>mt_j6ENpc8--_
mt_BLzNxSSdWu>mt_tn1rY9GbEZ
mt_BLzNxSSdWu>mt_vauULTecMH
mt_-bMnJcPJy8>mt_J4j7d3iAfg
mt_-bMnJcPJy8>mt_Zt30Gxi-qp
mt_bn5ggh84qD>mt_18qkgxr_-T
mt_bn5ggh84qD>mt_mKAZTqItRG
mt_bn5ggh84qD>mt_Z3G_97fnha
mt_BnabTHkNIp>mt_dpM1l5IOk6
mt_BO_AHGLCk0>mt_4pLvMN8uzL
mt_BO_AHGLCk0>mt_IhWzO4sQPg
mt_BOG5zRYtQz>mt_URTJbS3hhs
mt_BOG5zRYtQz>mt_uVaS12lN1i
mt_bO-njVOige>mt_hCVPYlF-7Y
mt_bPFToj0OhZ>mt_K6qtan847r
mt_brgde1Vx0P>mt_1J5fwxNDxL
mt_brgde1Vx0P>mt_AylKwhbDWM
mt_brgde1Vx0P>mt__bhJX2SuFJ
mt_BtMbZibZUj>mt_F978c32kDr
mt_BVpB5wyijZ>mt_PiWZA8Z0ZJ
mt_bvxkT1nepy>mt_mmudyxf7bT
mt_bvxkT1nepy>mt_szw1Ln490b
mt_BX4D8cCFtQ>mt_g4YSiOCS8g
mt_BX4D8cCFtQ>mt_g_M4Vh_pK7
mt_BX4D8cCFtQ>mt_K8DJzqbksM
mt_BX4D8cCFtQ>mt_Ruk2-lyGPZ
mt_ByXgbTld6R>mt_PiWZA8Z0ZJ
mt_Bztatrv-_v>mt_13CtLTcWUB
mt_Bztatrv-_v>mt_pwo81ls_J-
mt_Bztatrv-_v>mt_V_wIdRZLsG
mt_Bztatrv-_v>mt_YynJoQcm_M
mt_c29FaCTNsx>mt_u5HkSxZECM
mt_c29FaCTNsx>mt_xppl18avyY
mt_c29FaCTNsx>mt_ylXdiVRAYv
mt_C3eNLQJlgt>mt_2yas4Unc8o
mt_C3eNLQJlgt>mt_jBQS-CicNn
mt_-c4Ca_nBzX>mt_J4j7d3iAfg
mt_-c4Ca_nBzX>mt_k2WE0-22-4
mt_-c4Ca_nBzX>mt_xSgAgg9Ej_
mt_C7abt7pRr6>mt_BtMbZibZUj
mt_C7FNeIDGc6>mt_lp1eTsQen7
mt_C7FNeIDGc6>mt_pJ5zsocdNx
mt_C7FNeIDGc6>mt_tiPyEkm4cU
mt_C9ZfT-4cgn>mt_GRWwTDZ3wD
mt_C9ZfT-4cgn>mt_PZ909yPrEC
mt__casygEB85>mt_5NwqN6pf_A
mt__casygEB85>mt_Ac7oMWhyPw
mt_cB7hV8sw7X>mt_82KKv0Fca3
mt_cB7hV8sw7X>mt_9P9o6d0Qm3
mt_cB7hV8sw7X>mt_AvJMWQbDsr
mt_CBHwluE6Lp>mt_a1FdAsRKOF
mt_CBxOcjh69x>mt_5S4byWDX6n
mt_CBxOcjh69x>mt_EaWjCyn8W2
mt_CBxOcjh69x>mt_v3Vz_Pgjjv
mt_cChv2j_-Da>mt_glPPG-kTQY
mt_cChv2j_-Da>mt__t4afSyZRm
mt_Cc-QHVo747>mt_yrMniCJu_S
mt_CDa5AVakLE>mt_mpS-JK_p_m
mt_CDa5AVakLE>mt_XuHmIn2xje
mt_cdMlC7EpTJ>mt_e4V6hvcuEJ
mt_cdMlC7EpTJ>mt_liIW336odh
mt_cdMlC7EpTJ>mt_oqziWKry-L
mt_cEQqskOaoo>mt_bkMDDstwwG
mt_cEQqskOaoo>mt_H8dEMH_wik
mt_cEQqskOaoo>mt_Jd2aWEUJ9G
mt_cEQqskOaoo>mt_KA5j5OeGvw
mt_cEQqskOaoo>mt_nIl1kKZHsk
mt_cEzX5r7kp0>mt_1wxwg782yX
mt_cEzX5r7kp0>mt_oR6dwRj2Ll
mt_cEzX5r7kp0>mt_-vsLvsxp0L
mt_cFltwUQi-d>mt_g3W0mdADVu
mt_cFltwUQi-d>mt_-hTTat0mBR
mt_cFltwUQi-d>mt_LpSuPgL31x
mt_cFltwUQi-d>mt_vKcxX6iNOA
mt_c-F__Qe23X>mt_CSGqz245rV
mt_c-F__Qe23X>mt_IlyE-Sm8k5
mt_c-F__Qe23X>mt_N1744276Zu
mt_c-F__Qe23X>mt_vFYFvgrPgD
mt_Cg8VPguS_V>mt_fmm-P17Vka
mt_Cg8VPguS_V>mt_JH_6RpNWjr
mt_Cg8VPguS_V>mt_lU-2aTRB9f
mt_ChjMU2GDJa>mt_r8XnXwRA6g
mt_ChjMU2GDJa>mt_u5HkSxZECM
mt_cJ8CeyRKKs>mt_B1ATUEVNPz
mt_cJ8CeyRKKs>mt_bvxkT1nepy
mt_cJ8CeyRKKs>mt_g4YSiOCS8g
mt_cJ8CeyRKKs>mt_szw1Ln490b
mt_cJjnPjuvCU>mt_i1kk9HDctI
mt_cJjnPjuvCU>mt_jIszRCO2ij
mt_cJjnPjuvCU>mt_miGrca8zaS
mt_CK2orHetl3>mt_aO018DkCun
mt_ck57CDFGet>mt_WNBHZ1d94L
mt_ckpA3oZQ44>mt_68pIoiiG4g
mt_cM8YS6NXqi>mt_4uPnLieBPN
mt_cM8YS6NXqi>mt_Fw0bbM1e_g
mt_cM8YS6NXqi>mt_FZ_ixwU1p1
mt_cM8YS6NXqi>mt_L1469gt34A
mt_cM8YS6NXqi>mt_m31_gPS8F1
mt_cM8YS6NXqi>mt_oLHXfLujmh
mt_cM8YS6NXqi>mt_Sa48W7KXB5
mt_cM8YS6NXqi>mt_zir5yyAzUB
mt_cMmG8VLbAp>mt_5_kErPeeNu
mt_cMmG8VLbAp>mt_fhqVdj4BYr
mt_cMmG8VLbAp>mt_g1qgxmlJQ2
mt__CMXZiPfTV>mt__KHQttMde3
mt_cOknxrYhwL>mt_2oswCNuapH
mt_cOknxrYhwL>mt_HFN1pGASpZ
mt_cOknxrYhwL>mt_Mb1JUJmnbX
mt_cpDpjJaE5u>mt_JmMtZCifJB
mt_cpDpjJaE5u>mt_YB0qF5KX9C
mt_cpDpjJaE5u>mt_ZJu8s-Q1xa
mt_cPZwlUk8Nd>mt_fR0UtsSREU
mt_cq711F7ruL>mt_CrGnpVjnk8
mt_cq711F7ruL>mt_vpMDMbx4pc
mt_Cqm8iy48UI>mt_2yas4Unc8o
mt_Cqm8iy48UI>mt_r8XnXwRA6g
mt_cqSf213hSa>mt_KaF0SQvaiu
mt_cqSf213hSa>mt_skYly2Qm01
mt_CqzsM0BDFP>mt_doVAdMqfJg
mt_CqzsM0BDFP>mt_M_xcaRcvSo
mt_CrGnpVjnk8>mt__ab4knIaSL
mt_CrGnpVjnk8>mt_RgQxPddV8v
mt_CrGnpVjnk8>mt_SbEaQnMQoD
mt_CSGqz245rV>mt_19qy2uuaKp
mt_CSGqz245rV>mt_mMMXD4v9Sh
mt_cSPtyLF3q1>mt_CVywzrjT_c
mt_cSPtyLF3q1>mt_yrSdVrXrsF
mt_cSz7XTxVAx>mt_udgPy5oAvR
mt_cSz7XTxVAx>mt_uP9faJlnRq
mt_cU3LcEVkBQ>mt_f_dMmvzxwo
mt_cU3LcEVkBQ>mt_N8CpN1EJrP
mt_cU3LcEVkBQ>mt_yBJyCfhtem
mt_CUmjcE7W6c>mt_3VmBdlAeOZ
mt_CUmjcE7W6c>mt_q9EaJc2FP8
mt_CUmjcE7W6c>mt_ZM9mhHsyYZ
mt_cUMUYkDqZp>mt_8ad4U6msea
mt_cUMUYkDqZp>mt_CSGqz245rV
mt_curkA82CmO>mt_sMAcZW6vWM
mt_cVp_nop-5L>mt__BbOjiY5A5
mt_cVp_nop-5L>mt_oajUvqAiBJ
mt_CVywzrjT_c>mt_7VrR1GzhrN
mt_CVywzrjT_c>mt_E5KC4AnRLW
mt_CVywzrjT_c>mt_QrVF5n7vci
mt_CVywzrjT_c>mt_wvcFlwOrDl
mt_cxJRc15osy>mt_lp1eTsQen7
mt_cxJRc15osy>mt_tiPyEkm4cU
mt_CyV7crZ8hl>mt_b6kZgqolEd
mt_CyV7crZ8hl>mt_htAYR-iCFF
mt_CyV7crZ8hl>mt_Pl-nsjYGZ3
mt_D4lyx0iYyB>mt_0zqOTjjW2k
mt_D4lyx0iYyB>mt_7OJjLOl0fz
mt_D4lyx0iYyB>mt_9EoS35vaYB
mt_D4lyx0iYyB>mt_aO018DkCun
mt_D4lyx0iYyB>mt_pwo81ls_J-
mt_D4lyx0iYyB>mt_v3Vz_Pgjjv
mt_d7XktBQPxm>mt_IuHa5UI5od
mt_d8al9JcajP>mt_6oxQPNLHNv
mt_d8al9JcajP>mt_EXlmTURK_o
mt_DA7-JYRvtP>mt_9nxyFoYD_b
mt_DbI1kNg_0R>mt_AB-TEMXSGJ
mt_DbI1kNg_0R>mt_fkcxpeYP85
mt_DbI1kNg_0R>mt_KRNU0IOKfO
mt_DbI1kNg_0R>mt_TMOzMCE17H
mt_DbI1kNg_0R>mt_VI5kdtf28e
mt_DbI1kNg_0R>mt_-YYnLLIZh5
mt_DbXWivdJFB>mt_13CtLTcWUB
mt_DbXWivdJFB>mt_I047mKeeaq
mt_DbXWivdJFB>mt_Ruk2-lyGPZ
mt_DCelLx_H1A>mt_-0cjwyYhce
mt_DCelLx_H1A>mt_oLHXfLujmh
mt_DCelLx_H1A>mt_v3Vz_Pgjjv
mt_DCelLx_H1A>mt_xVW5U41tbp
mt_deexfCHU9m>mt_e6PP4ip39V
mt_d-EKO-pKkP>mt_DA7-JYRvtP
mt_DI1cyAyGyN>mt_JyfLtl_nhw
mt_Dj2xr8CoI0>mt_jc9k_HJQGd
mt_Dj2xr8CoI0>mt_PrWc-HZzDl
mt_DJh2JPwTf6>mt_13CtLTcWUB
mt_DJh2JPwTf6>mt_BnabTHkNIp
mt_DJh2JPwTf6>mt_dpM1l5IOk6
mt_dknMcCqvoY>mt_phpn6KhCAv
mt_dknMcCqvoY>mt_RTwmvr9R7V
mt_DkzsZdyaL2>mt_mDp-1vlL3R
mt_DkzsZdyaL2>mt_S7UTAhptLi
mt_DLcEzmmj2r>mt_cChv2j_-Da
mt_DLcEzmmj2r>mt_xWg0lI_gG4
mt_dlm3NspUyy>mt_MOY_2Cqalz
mt_dlm3NspUyy>mt_rymBfJmvFl
mt_dmFnJzxKwz>mt_IX37F4rNed
mt_dmFnJzxKwz>mt_ukLvUD8DFA
mt_dmNvjroCPT>mt_WcfaSfVT33
mt_DMvKfP4uGC>mt_WBfj79OqXz
mt_DNYQLahbfa>mt_liIW336odh
mt_DNYQLahbfa>mt_WtIFJSCQIT
mt_DOe893F6gN>mt_4lp_b5Pzik
mt_DOe893F6gN>mt_KaF0SQvaiu
mt_DOe893F6gN>mt_zd0YkB3xNj
mt_doVAdMqfJg>mt_OiDHqtLoln
mt_doVAdMqfJg>mt_oN7fI4d_kU
mt_doX1BhmFgk>mt_YzM5goBctT
mt_DQk9oDE7gr>mt_LxK9OKZQZX
mt_DQk9oDE7gr>mt_ydtcIBwHB9
mt_dRCnJEIwk4>mt_9EoS35vaYB
mt_dRCnJEIwk4>mt_sQpIV0-qY7
mt_dRCnJEIwk4>mt_yxL1v4LuqR
mt_DRlbMok2lT>mt_Ep7TDFuYUa
mt_DRlbMok2lT>mt_TqDq6jyOmL
mt_dRLP8g0SAg>mt_curkA82CmO
mt_dRLP8g0SAg>mt_FW9_8F52bw
mt_ds2TOtP8I1>mt_4A7FYmvVhA
mt_ds2TOtP8I1>mt_ZBMcX2oRor
mt_dSeFrAWE4v>mt_BLQ2_OXPod
mt_dSeFrAWE4v>mt_S9SKah-yi_
mt_-DuXzMVVXQ>mt_sMAcZW6vWM
mt_DVSHx3YMkN>mt_dmFnJzxKwz
mt_DVSHx3YMkN>mt_furAIwoO9t
mt_DW2D1c0fKx>mt_QCgbiVrwnp
mt_DW2D1c0fKx>mt_THl9GLxwoL
mt_DW2D1c0fKx>mt_uG2mjHFOlO
mt_d-WZC2OyMB>mt_Ep7TDFuYUa
mt_d-WZC2OyMB>mt_IL86kadLSS
mt_d-WZC2OyMB>mt_mQcWGh02no
mt_dXq9VWm31W>mt_19j_5AuuQI
mt_dXq9VWm31W>mt_EBYGhd8X3x
mt_dXq9VWm31W>mt_Kr3IyA6m-O
mt_DyGBW3ZHh3>mt_aPBzD28_mT
mt_DyGBW3ZHh3>mt_wQ89AEXhz3
mt_DyGBW3ZHh3>mt_zOWwLxa77y
mt_E1wR8IfCV6>mt_13CtLTcWUB
mt_E1wR8IfCV6>mt_L1469gt34A
mt_e1Yr6rhRNW>mt_MlD0gwLSw9
mt_e3-_toGuWf>mt_MVovx37Xct
mt_e4x3l2JeLI>mt_cqSf213hSa
mt_e4x3l2JeLI>mt_DOe893F6gN
mt_E5ju6kQSu3>mt_kvrvpQris4
mt_E5ju6kQSu3>mt_rymBfJmvFl
mt_E5KC4AnRLW>mt_sSQlLOnAow
mt_E5YbLvMgLL>mt_VLu59hpQ4T
mt_e6PP4ip39V>mt_L1469gt34A
mt_E7avIa-tcE>mt_szw1Ln490b
mt_e7filQgayF>mt_14T5yPXUq_
mt_e7filQgayF>mt_ZLqYE7la4Z
mt_e8CZ7E5qW7>mt_7XcCG43ZZW
mt_EaWjCyn8W2>mt_0zqOTjjW2k
mt_EaWjCyn8W2>mt_bK84sPehyP
mt_EaWjCyn8W2>mt_Bztatrv-_v
mt_EaWjCyn8W2>mt_D4lyx0iYyB
mt_EaWjCyn8W2>mt_LRzjbo1Fn6
mt_EaWjCyn8W2>mt_pwo81ls_J-
mt_EbiGRVK8uR>mt_cU3LcEVkBQ
mt_EbiGRVK8uR>mt_VY3rBq8RyP
mt_ebPelt-qAl>mt_Ep7TDFuYUa
mt_ebPelt-qAl>mt_FP-mjXaq3B
mt_EBYGhd8X3x>mt_8RmpkDxT9L
mt_EBYGhd8X3x>mt_ehGS_uVSJv
mt_EBYGhd8X3x>mt_IM1G_7QzTa
mt_edaoZRkK6M>mt_yDZbQODIwp
mt_EDgw64OmfA>mt_kdWoAel3Zl
mt_EDgw64OmfA>mt_QqG6IdmTSE
mt_EedcpioR0v>mt_kH1DzOPsXG
mt_EedcpioR0v>mt_ofOGCQ7FWj
mt_Eehl12cSnN>mt_KmPZ5diLEP
mt_efOeaGFyGM>mt_hR2Y7NhMSY
mt_efOeaGFyGM>mt_i5_HnoFOYw
mt_efOeaGFyGM>mt_SH7QgFl8-v
mt_efOeaGFyGM>mt_Uq5vYqboCR
mt_EGIlsfHxb6>mt_iycQEai3dK
mt_EGIlsfHxb6>mt_NYA50DFcOO
mt_EGIlsfHxb6>mt_R6YoRXkRxS
mt_EGIlsfHxb6>mt_uQljqc0J5j
mt_ehC1wsdmUz>mt_rbPioPELM1
mt_ehC1wsdmUz>mt_UKmtuAsSLN
mt_ehC1wsdmUz>mt_ylruY6VhOf
mt_ehGS_uVSJv>mt_ezc2m_0dzN
mt_EHiM4_qg1R>mt_8ad4U6msea
mt_EHiM4_qg1R>mt_vFYFvgrPgD
mt_eiB3-6pu6a>mt_GzcJEVkNRn
mt_eiB3-6pu6a>mt_WtcFrxGOgw
mt_EIbltgXRWR>mt_H9RAGGiHBL
mt_EIbltgXRWR>mt_v9uYnIY5-B
mt_eKJG-0eC6D>mt_bESTSBB0wK
mt_eKJG-0eC6D>mt_Cqm8iy48UI
mt_eKJG-0eC6D>mt_fmm-P17Vka
mt_eKJG-0eC6D>mt_iEXqN48w3x
mt__EL7DHjf5R>mt_LTb0ZReMR2
mt__EL7DHjf5R>mt_r6oKXpN0er
mt_EmR5n58jZt>mt_DyGBW3ZHh3
mt_EmR5n58jZt>mt_wh3UqnWsa7
mt_eMtV6tBSJm>mt_GzcJEVkNRn
mt_enj1sMcfOT>mt_I65kFjWwnF
mt_enj1sMcfOT>mt_N8CpN1EJrP
mt_enj1sMcfOT>mt_qzwQAOfurw
mt_enj1sMcfOT>mt_yBJyCfhtem
mt_eoPcc4nrBE>mt_HveO1bOXpJ
mt_E_OryWIYkn>mt_KmPZ5diLEP
mt_E_OryWIYkn>mt_xjl6AEhnjk
mt_eosO26KE-Z>mt_Nj32xtOhno
mt_eosO26KE-Z>mt_UMOjbmLcbM
mt_eosO26KE-Z>mt_Zy-CKUkq34
mt_Ep7TDFuYUa>mt_FbDKeLfBCo
mt_Ep7TDFuYUa>mt_ndGqFPWyen
mt_Ep7TDFuYUa>mt_NoB20kVa4w
mt_EQQWKz03P8>mt_iYOcfzFqMw
mt_EQQWKz03P8>mt_-YYnLLIZh5
mt_eSv_w46u6H>mt_1YwOCMMwD8
mt_ewmuMMPAzP>mt_aPBzD28_mT
mt_ewmuMMPAzP>mt_cChv2j_-Da
mt_excSPNHJWZ>mt_bKlnc7dyVK
mt_EXlmTURK_o>mt_2XDGT5tei1
mt_EXO1bJ3G_v>mt_Mp_CpVK6e-
mt_EXO1bJ3G_v>mt_NPTjGJIyb3
mt_EXO1bJ3G_v>mt_w4OYcWJs6H
mt_EygMHKs8Ed>mt_13CtLTcWUB
mt_EygMHKs8Ed>mt_cM8YS6NXqi
mt_EygMHKs8Ed>mt_l6OpmOKMuT
mt_EygMHKs8Ed>mt_QH-Fs97twT
mt_EygMHKs8Ed>mt_xVW5U41tbp
mt_ezc2m_0dzN>mt_OvyoRo47K-
mt_ezc2m_0dzN>mt_zuKAX6lcYR
mt_f4O__f3OU4>mt_CSGqz245rV
mt_f4O__f3OU4>mt_W_CNRTBgYR
mt_f67qGDhyfi>mt_1VSfm9yiLn
mt_f67qGDhyfi>mt_3JgrHY221M
mt_f67qGDhyfi>mt_fLOkq-HfPB
mt_f8n4txtLej>mt_6lHBTwQPrS
mt_f8n4txtLej>mt_mB7DVai-Uf
mt_f8n4txtLej>mt_n6GhzDPllD
mt_F978c32kDr>mt_frDIaXzWbx
mt_f9syMry-0S>mt_3duNkf6Qmr
mt_f9syMry-0S>mt_scbDHJZZHK
mt_FAXjFkgG6X>mt_aPBzD28_mT
mt_FAXjFkgG6X>mt_DW2D1c0fKx
mt_FAXjFkgG6X>mt_u23IGDxOpk
mt_FAXjFkgG6X>mt_wvcFlwOrDl
mt_FbDKeLfBCo>mt_Kr3IyA6m-O
mt_FbDKeLfBCo>mt_MyGblah2yY
mt_FbDKeLfBCo>mt_vKcxX6iNOA
mt_fbYbe3YSVj>mt_tXxxCFl32J
mt_fCvmdI6xGO>mt_0NlbulkB5P
mt_FDKd7I79JZ>mt_MlD0gwLSw9
mt_FDKd7I79JZ>mt_W_CNRTBgYR
mt_f_dMmvzxwo>mt_6-MYToNZ39
mt_f_dMmvzxwo>mt_oL9s_bufDp
mt_fDoE-pL6Jv>mt_zVLOm6U7bh
mt_fEuoBYw6bU>mt_Mnodea7mG_
mt_fEuoBYw6bU>mt_sBcRdUfAzV
mt_FGCFUCqJBB>mt_o8ciHks8t2
mt_FGCFUCqJBB>mt_PJyCGJz5Hv
mt_FHIAv6dfhU>mt_K5jM7vlVhA
mt_FHIAv6dfhU>mt_nZkL5-XjRX
mt_fhqBH9scsU>mt_bABr-c2DfV
mt_fhqVdj4BYr>mt_IhWzO4sQPg
mt_fhqVdj4BYr>mt_nRF_VRntrW
mt_fhqVdj4BYr>mt_Pl-nsjYGZ3
mt_fhqVdj4BYr>mt_PrWc-HZzDl
mt_fhqVdj4BYr>mt_TlLE4cZgOr
mt_fI-8iqf_Id>mt_go5i87u2b9
mt_fI-8iqf_Id>mt_jc9k_HJQGd
mt_FieL-vVTI_>mt_2uHYdoxD0H
mt_FieL-vVTI_>mt_FnUJMXPUZX
mt_FieL-vVTI_>mt_GpltXPoaoc
mt_FieL-vVTI_>mt_RXnyhCRYXA
mt_FIkqA0qhnj>mt_cPZwlUk8Nd
mt_FIkqA0qhnj>mt_SsS7GptD_o
mt_fk33IEGP-T>mt_EHuU1ZeUFA
mt_fk33IEGP-T>mt_K0mZxY2AM8
mt_fkcxpeYP85>mt_-UAxilUtUt
mt_fkwcCB5px7>mt_AiWlJfvC3O
mt_fKwgN61ttR>mt_bKlnc7dyVK
mt_fL1Xz8ostr>mt_6-MYToNZ39
mt_fL1Xz8ostr>mt_mLPEMpYb_R
mt_fL1Xz8ostr>mt_VLu59hpQ4T
mt_Fl7b8q9pI1>mt_TqDq6jyOmL
mt_fLOkq-HfPB>mt_xppl18avyY
mt_fLOkq-HfPB>mt_yJmvUCCym7
mt_-F_Lv_apzH>mt_CDa5AVakLE
mt_-F_Lv_apzH>mt_MWXPiaTnEu
mt_-F_Lv_apzH>mt_Yw1_4Nfsql
mt_fMd7v87IiI>mt_BtMbZibZUj
mt_FNSeo9_T2Z>mt_FIkqA0qhnj
mt_FnUJMXPUZX>mt_b7T-CjOYUR
mt_FnUJMXPUZX>mt_ePXg_XyCKU
mt_FnUJMXPUZX>mt_ESgc4YBw-a
mt_FnUJMXPUZX>mt_h0gJcSuwdL
mt_FP-mjXaq3B>mt_Ep7TDFuYUa
mt_fpPLWFIRVo>mt_Bztatrv-_v
mt_fpPLWFIRVo>mt_IzlVK0Eony
mt_fpPLWFIRVo>mt_wHN14Unk7h
mt_fqAkSv3cUE>mt_44HkROUnzE
mt_fqAkSv3cUE>mt_6aJUzBYGNs
mt_fqAkSv3cUE>mt_CBxOcjh69x
mt_Fqna9qHffr>mt_5_kErPeeNu
mt_Fqna9qHffr>mt_DbI1kNg_0R
mt_Fqna9qHffr>mt_g1qgxmlJQ2
mt_Fqna9qHffr>mt_X4CJpPRxae
mt_fR0UtsSREU>mt_dmNvjroCPT
mt_fR0UtsSREU>mt_oAK9GXSfqV
mt_frDIaXzWbx>mt_1KCwbGvm1F
mt_fT4G0QloX5>mt_ofOGCQ7FWj
mt_fT4G0QloX5>mt__p5n8z5soJ
mt_furAIwoO9t>mt_fL1Xz8ostr
mt_furAIwoO9t>mt_hJW7hVflm3
mt_FuVEZ1Ac9s>mt_IY3KwGLZgk
mt_FuVEZ1Ac9s>mt_k1HXbEwG8f
mt_FuVEZ1Ac9s>mt_mKNmXqz_Oo
mt_FuVEZ1Ac9s>mt_mqQ-DtH5m-
mt_FuVEZ1Ac9s>mt_rOqo-8GeKt
mt_FuVEZ1Ac9s>mt_YNrrNE23dZ
mt_FvEq4heNBx>mt_MCu_SNg_OW
mt_FvEq4heNBx>mt_WsM4EmdOLe
mt_FVERuBoCD1>mt_PifbJOuXrG
mt_FVERuBoCD1>mt_qzGADV-NGe
mt_FW9_8F52bw>mt_4A4RpX-Go9
mt_FW9_8F52bw>mt_82KKv0Fca3
mt_FW9_8F52bw>mt_r8XnXwRA6g
mt_FW9_8F52bw>mt_sMAcZW6vWM
mt_FwI7q7DSIx>mt_NS5t-Jzlh8
mt_FX4a2Q8XXN>mt_nNNVrLqPW3
mt_fxPtngwUfz>mt_A-FyLLLLzy
mt_fxPtngwUfz>mt_h0gJcSuwdL
mt_fxPtngwUfz>mt_i5_HnoFOYw
mt_FYK8m6eHQm>mt_BhYJZUsErp
mt_FYK8m6eHQm>mt_EqXlZfB4jp
mt_FYK8m6eHQm>mt_QdMMLRYWhn
mt_fZTn0W_iZR>mt_kw7xmp68rU
mt_fZTn0W_iZR>mt_m1W6nTQJ2b
mt_fZTn0W_iZR>mt_RFeVlw0QvX
mt_g1qgxmlJQ2>mt_7nduoLvoB1
mt_g1qgxmlJQ2>mt_8QOeG3CuKc
mt_g1qgxmlJQ2>mt_KRNU0IOKfO
mt_g1qgxmlJQ2>mt_scbDHJZZHK
mt_G3sVFQNCme>mt_5NwqN6pf_A
mt_G3sVFQNCme>mt_QaYfeVL-0C
mt_g3W0mdADVu>mt_-hTTat0mBR
mt_g4YSiOCS8g>mt_83gRQ9OPkc
mt_g4YSiOCS8g>mt_fDoE-pL6Jv
mt_g4YSiOCS8g>mt_SdIWVjzopp
mt_-G6erQvLig>mt_0_K-GrKQpd
mt_-G6erQvLig>mt_bqL8DD1SbV
mt_-G6erQvLig>mt_KsKLVW_ssY
mt_-G6erQvLig>mt_vAP_A986IQ
mt_g9RcQOhU5d>mt_bABr-c2DfV
mt_g9RcQOhU5d>mt_VfA4xo4kUv
mt_Gag_h98jWP>mt_EDgw64OmfA
mt_Gag_h98jWP>mt_JwP9QFv6gQ
mt_gbTyzvnWzr>mt_enj1sMcfOT
mt_gbTyzvnWzr>mt_u7Jxjjatkh
mt_GbZFuGDFsa>mt_f9syMry-0S
mt_GbZFuGDFsa>mt_hjJkBWruO6
mt_GbZFuGDFsa>mt_TMOzMCE17H
mt_GbZFuGDFsa>mt_z9jn9HogfE
mt_GDG9_SZmsO>mt_gtTl3R5buH
mt_GDG9_SZmsO>mt_iNdrM2-oJf
mt_GDtFU5fyUv>mt_1YwOCMMwD8
mt_GDtFU5fyUv>mt_AabJisinfi
mt_GDtFU5fyUv>mt_sHJqh6UUya
mt_Ge4Wtg6QMM>mt_e3-_toGuWf
mt_Ge4Wtg6QMM>mt_MVovx37Xct
mt_Ge4Wtg6QMM>mt_rTn43s8RNX
mt_Ge4Wtg6QMM>mt_YQkUdIHO8L
mt_gf4RUcACLg>mt_0VOZSVjo6c
mt_gf4RUcACLg>mt_KA5j5OeGvw
mt_gf4RUcACLg>mt_Ytd8XC3eQr
mt_GF6L7J4MNN>mt_6xsEXxKdUX
mt_g_fkAqmz72>mt_KwdjWEmMNo
mt_ggcamLzXAy>mt_LhkP_KKIRS
mt_GheLsWvrJ4>mt_bqL8DD1SbV
mt_GheLsWvrJ4>mt_mwirOvigWD
mt_GheLsWvrJ4>mt_ZJu8s-Q1xa
mt_ghF3Vv6taM>mt_OvyoRo47K-
mt_ghF3Vv6taM>mt_zuKAX6lcYR
mt_ghK1mnEstc>mt_mayItsxMUu
mt_ghK1mnEstc>mt_ndGqFPWyen
mt_-gkJdxJUQT>mt_nwSWPTENmv
mt_-gkJdxJUQT>mt_pJ5zsocdNx
mt_glPPG-kTQY>mt_m1W6nTQJ2b
mt_glPPG-kTQY>mt_THl9GLxwoL
mt_GLY3R3YSlf>mt_32B7xjUPwF
mt_GLY3R3YSlf>mt_aFvsj35QzC
mt_GLY3R3YSlf>mt_ggcamLzXAy
mt_GLY3R3YSlf>mt_sSQlLOnAow
mt_GLY3R3YSlf>mt_wvcFlwOrDl
mt_gLy3ZgZWiN>mt_4i-FKXDDXh
mt_gLy3ZgZWiN>mt_YPSx5pbpVl
mt_Gm12BzcCfX>mt_AB-TEMXSGJ
mt_Gm12BzcCfX>mt_NYsz6QgaaE
mt_Gm12BzcCfX>mt_zCGwH1OQZa
mt_g_M4Vh_pK7>mt_C7FNeIDGc6
mt_g_M4Vh_pK7>mt_lp1eTsQen7
mt_gMSFymQlrW>mt_dmFnJzxKwz
mt_gMSFymQlrW>mt_jIcgbCmziD
mt_gMSFymQlrW>mt_V6456X6pJE
mt_gNUE4B3vuk>mt_14T5yPXUq_
mt_gNUE4B3vuk>mt_AabJisinfi
mt_gNUE4B3vuk>mt_ifPDOYvUqm
mt_go5i87u2b9>mt_bj1YCgNWUx
mt_goZW_hQUa4>mt_v3Vz_Pgjjv
mt_GpltXPoaoc>mt_4ubP_RMg9o
mt_GpltXPoaoc>mt_p-nbe0w_lf
mt_GpltXPoaoc>mt_q7zxOloj_L
mt_GpltXPoaoc>mt_SmghasIvbT
mt_GQpqoR5YOc>mt_5r47Pvstyn
mt_gR5_n99Ntt>mt_V-ldQp56bF
mt_gR5_n99Ntt>mt_YNe6siFTFq
mt_GRWwTDZ3wD>mt_LpSuPgL31x
mt_GRWwTDZ3wD>mt_PZ909yPrEC
mt_gTDqxYkLs9>mt_4IVWRAZoNC
mt_gTDqxYkLs9>mt_6Z42wJaKYG
mt_gTDqxYkLs9>mt_lWqmKn5Jvr
mt_gtTl3R5buH>mt_B1zj1RwQ3a
mt_gtTl3R5buH>mt_PZ909yPrEC
mt_gu0NPDvlhY>mt_XLP1IM3Qbb
mt_guaaD6Dn2M>mt_oNWXXAn3cn
mt_GugVunb2lI>mt_klyw-tdlhP
mt_GugVunb2lI>mt_scBgiMKhG_
mt_gv_uoHkdjR>mt__kFxuAgs6d
mt_gv_uoHkdjR>mt_rML9unnd9x
mt_gx6KQK5-Kx>mt_AabJisinfi
mt_gx6KQK5-Kx>mt_eiB3-6pu6a
mt_gxCIASSezX>mt_K5jM7vlVhA
mt_GzcJEVkNRn>mt_Jvvh5P06NV
mt_gZIo5oiBMt>mt_mLPEMpYb_R
mt_GZuoYaDdWd>mt_-3udyo6VyB
mt_H0ajATAlus>mt_v33BwiyRnd
mt_H0ajATAlus>mt_yHQacItlhf
mt_h0CVtqI2xo>mt_MFfYcnv6Tv
mt_h0gJcSuwdL>mt_AabJisinfi
mt_h0gJcSuwdL>mt_ePXg_XyCKU
mt_h0gJcSuwdL>mt_ESgc4YBw-a
mt_h0gJcSuwdL>mt_U4cIBXVug4
mt_H1pAi4F_Oh>mt_bvxkT1nepy
mt_H1pAi4F_Oh>mt_mMMXD4v9Sh
mt_h3vmvQW5Wa>mt_86DyHo9zO3
mt_H3ZDK0EYNV>mt_2bnXrfS4Iq
mt_H4bLNkDrGJ>mt_vFYFvgrPgD
mt_H6LlpWgEYS>mt_ChjMU2GDJa
mt_H7DquwQi_F>mt_WBfj79OqXz
mt__h7hvT4tEb>mt_yqAL6O5i_v
mt_H8dEMH_wik>mt_H4YZ1rSKP3
mt_H8dEMH_wik>mt_TU3BcLOgiV
mt_H8dEMH_wik>mt_wvcFlwOrDl
mt_H8OgKZbgGe>mt_DCelLx_H1A
mt_H8OgKZbgGe>mt_EaWjCyn8W2
mt_H8OgKZbgGe>mt_R7LEuZjTmx
mt_H9RAGGiHBL>mt_7GwWplh-48
mt_H9RAGGiHBL>mt_oiqsIP97V3
mt_Hah24nbToi>mt_NNNbPccwB4
mt_haNr13NIuN>mt_LH714Riydn
mt_haNr13NIuN>mt_U_8iVFZuHH
mt_haNr13NIuN>mt_v5yDTWEiyQ
mt_HBcvu0UxYe>mt_NS5t-Jzlh8
mt_hbDflQfW-U>mt_-0cjwyYhce
mt_hbDflQfW-U>mt_TMOzMCE17H
mt_hbDflQfW-U>mt_v6CBCMuvz1
mt_hbe_kdE_7C>mt_wvcFlwOrDl
mt_hBZwbst0ow>mt_A-FyLLLLzy
mt_hBZwbst0ow>mt_RVK655t391
mt_hCVPYlF-7Y>mt_X5cypSGoGU
mt_HCweOHWSiu>mt_hzkNpp2PdV
mt_HCweOHWSiu>mt_IdFxLz-UW9
mt_HdI1y5KsBl>mt_nFBLNoChD0
mt_HdI1y5KsBl>mt_Z3G_97fnha
mt_hdrMoiTgqu>mt_4MFUAsbx_6
mt_hdrMoiTgqu>mt_8H2kO4k2B9
mt_HFN1pGASpZ>mt_2oswCNuapH
mt_HFN1pGASpZ>mt_a6AYrbb7x4
mt_HFN1pGASpZ>mt_yCmYV9ruQu
mt_HFRYjTb-Z5>mt_ewmuMMPAzP
mt_HFRYjTb-Z5>mt_SrrsLiJkr3
mt_HhuSDxwDNM>mt_nvdpxAJTBG
mt_HhuSDxwDNM>mt_PZ909yPrEC
mt_hi8cVycbwn>mt_XirhnAB6Ye
mt_hImiKNiaNh>mt_4K1dr204Hi
mt_hImiKNiaNh>mt_hlGKg5M7qJ
mt_hImiKNiaNh>mt_liIW336odh
mt_hImiKNiaNh>mt_wvcFlwOrDl
mt_HJA2Oz-Zh1>mt_TgHxujL81r
mt_HJd-8EEC6N>mt_2OSTHTWDpa
mt_HJd-8EEC6N>mt_DbI1kNg_0R
mt_HJd-8EEC6N>mt_ZWTk6eP1qF
mt_hjJkBWruO6>mt_fI-8iqf_Id
mt_hjJkBWruO6>mt_jc9k_HJQGd
mt_hjtbA3g-Nn>mt_4-vfMgmCVB
mt_hjtbA3g-Nn>mt_uvILgZq9HN
mt_HJTuIGHvcR>mt_zfy1gOEewd
mt_HJTuIGHvcR>mt_zuKAX6lcYR
mt_hJW7hVflm3>mt_fL1Xz8ostr
mt_hJW7hVflm3>mt_SUOhjmRqv9
mt_hlGKg5M7qJ>mt_FHIAv6dfhU
mt_hlGKg5M7qJ>mt__Itf4aQZUj
mt_hlGKg5M7qJ>mt_oqziWKry-L
mt_hlGKg5M7qJ>mt_wvcFlwOrDl
mt_HLUqHJ9Y7n>mt_EDgw64OmfA
mt_HLUqHJ9Y7n>mt_LlMl2PbaZe
mt_hniI4E-OCE>mt_nvdpxAJTBG
mt_hniI4E-OCE>mt_OvyoRo47K-
mt_HnKbuCliNS>mt_IfEgu0X449
mt_HnKbuCliNS>mt_ndGqFPWyen
mt_HNOPGJYiRK>mt_0XxyaQLRhn
mt_HNOPGJYiRK>mt_nvdpxAJTBG
mt_HoJGVsMO7H>mt_miGrca8zaS
mt_HopZomN12L>mt_EedcpioR0v
mt_HopZomN12L>mt_kH1DzOPsXG
mt_HopZomN12L>mt_W5euSyU2sO
mt_hp2qJ-QRBn>mt_82KKv0Fca3
mt_hp2qJ-QRBn>mt__MDiDU9Vck
mt_HPf-dVtA3p>mt__ab4knIaSL
mt_HPf-dVtA3p>mt_RNRymbz5SO
mt_H_pNJ3ZI_S>mt_tedML_iu4Y
mt_Hqz5y_tWz2>mt_dmFnJzxKwz
mt_Hqz5y_tWz2>mt_ukLvUD8DFA
mt_hR2Y7NhMSY>mt_hRZyKvz1KN
mt_hR2Y7NhMSY>mt_SH7QgFl8-v
mt_HrgDjxcWvf>mt__CMXZiPfTV
mt_HRKzwEQJgO>mt_QhFEDyIwSO
mt_HRKzwEQJgO>mt_yXO7lQ9Yn7
mt_hRZyKvz1KN>mt_sBcRdUfAzV
mt_hRZyKvz1KN>mt_SH7QgFl8-v
mt_h_shhH-6DC>mt_h-z88yf9Pn
mt_h_shhH-6DC>mt_rkrG2w7WXI
mt_hsN-YvCNQY>mt_Wr6DDgr_kH
mt_-hTTat0mBR>mt_LpSuPgL31x
mt_HveO1bOXpJ>mt_Z5-fSCOBep
mt_hVpGOEz2kG>mt_i5_HnoFOYw
mt_hVpGOEz2kG>mt_R4AY0LKxfl
mt_hVpGOEz2kG>mt_uDJY0X0hgo
mt_Hw70LI5xza>mt_klyw-tdlhP
mt_HWYAspz-LK>mt_6eTZUwKQZr
mt_HWYAspz-LK>mt_82KKv0Fca3
mt_HWYAspz-LK>mt_nYU6x2E2T8
mt_HWYAspz-LK>mt_OyOYHlZ2_T
mt_HY8Yycu_rz>mt_6oxQPNLHNv
mt_HY8Yycu_rz>mt_a1FdAsRKOF
mt_HY8Yycu_rz>mt_B8JOz79O6t
mt_HY8Yycu_rz>mt_TMoHjMhRS2
mt_hyvHv2BCwb>mt_xACS3rWWDp
mt_hzkNpp2PdV>mt_gbTyzvnWzr
mt_hzkNpp2PdV>mt_-tcJeAhK5k
mt_HZvTriQWTh>mt_bj1YCgNWUx
mt_HZvTriQWTh>mt_go5i87u2b9
mt_HZyUwycFvf>mt_5OxKnrGEMP
mt_HZyUwycFvf>mt_PCX1jZZnf9
mt_HZyUwycFvf>mt_pTz6u49fQt
mt_HZyUwycFvf>mt_vFYFvgrPgD
mt_I047mKeeaq>mt_JpQUM1129q
mt_i2F1nWxJjv>mt_QhFEDyIwSO
mt_i2F1nWxJjv>mt_uDJY0X0hgo
mt_i4bDqjyglj>mt_cM8YS6NXqi
mt_i4bDqjyglj>mt_fDoE-pL6Jv
mt_i4bDqjyglj>mt_guaaD6Dn2M
mt_i4bDqjyglj>mt_YynJoQcm_M
mt_i5_HnoFOYw>mt_jBQS-CicNn
mt_i5_HnoFOYw>mt_Xt1cRqaBOW
mt_I5j1ZWo2cn>mt_kw7xmp68rU
mt_I5j1ZWo2cn>mt_THl9GLxwoL
mt_I65kFjWwnF>mt_o8ciHks8t2
mt_I65kFjWwnF>mt_OyOYHlZ2_T
mt_I65kFjWwnF>mt_p_jxNLdus4
mt_I65kFjWwnF>mt_QEr24lqzvH
mt_i80I-1MLP2>mt_bABr-c2DfV
mt_I9iSzpGRn5>mt_9NQEiYLQA3
mt_I9iSzpGRn5>mt_h-z88yf9Pn
mt_I9iSzpGRn5>mt_Wc6cOTQ1bA
mt_i9rJbuFO3p>mt_4WaKWECpcv
mt_i9rJbuFO3p>mt_jHgRQ4hR0g
mt_I_c57p0aGN>mt_islVn_P28Z
mt_I_c57p0aGN>mt_itldWmVItr
mt_idbKDrf9qZ>mt_ndGqFPWyen
mt_idbKDrf9qZ>mt_Xp-rj46S2w
mt_IdFxLz-UW9>mt_EbiGRVK8uR
mt_IdFxLz-UW9>mt_YQ64pzcLDl
mt_IegHBHERVa>mt_TqDq6jyOmL
mt_iEXqN48w3x>mt_4K1dr204Hi
mt_iEXqN48w3x>mt_ATYLKt0je-
mt_iEXqN48w3x>mt_PNSyfH56eQ
mt_IfEgu0X449>mt_hyvHv2BCwb
mt_IfEgu0X449>mt_Kr3IyA6m-O
mt_iFkd0CTwlA>mt_frDIaXzWbx
mt_iFkd0CTwlA>mt_P0HBNfp46z
mt_iFkd0CTwlA>mt_szw1Ln490b
mt_ifPDOYvUqm>mt_4Km38F4L-6
mt_ifPDOYvUqm>mt_AabJisinfi
mt_iGSfQg3g5c>mt_go5i87u2b9
mt_IHipFGTFEY>mt_14T5yPXUq_
mt_IHipFGTFEY>mt_42QD6nYjiZ
mt_IhWzO4sQPg>mt_TlLE4cZgOr
mt_Ii1hV4V5ql>mt_Fl7b8q9pI1
mt_II6iw4BmJI>mt_aVZJhPbc_1
mt_iiUdDUEEGY>mt_6EfevRyeFW
mt_iiUdDUEEGY>mt_JmMtZCifJB
mt_iiUdDUEEGY>mt_-YYnLLIZh5
mt_Ik-WC2ARPf>mt_26OJ9MetR9
mt_Ik-WC2ARPf>mt_8ShghTx0jd
mt_Ik-WC2ARPf>mt_Nj32xtOhno
mt_Ik-WC2ARPf>mt_pitjUcaAdy
mt_Ik-WC2ARPf>mt_rf23aL6KwH
mt_IL86kadLSS>mt_4emC463IyW
mt_IL86kadLSS>mt_UNzojLkNdm
mt_ilPrU0cbtT>mt__casygEB85
mt_ilPrU0cbtT>mt_G3sVFQNCme
mt_IlyE-Sm8k5>mt_2GDBmKCJxs
mt_IlyE-Sm8k5>mt_32B7xjUPwF
mt_IlyE-Sm8k5>mt_VXcua6-txq
mt_IM1G_7QzTa>mt_PgsHGYJMH-
mt_IM1G_7QzTa>mt_yJmvUCCym7
mt_iNdrM2-oJf>mt_LpSuPgL31x
mt_IntmJBg4VQ>mt_BhYJZUsErp
mt_IntmJBg4VQ>mt_t1JXeNgKcu
mt_iodbOOmEQs>mt_OltpfaX7l6
mt_iodbOOmEQs>mt_sXRHr7tfS5
mt_IoGOSAQ8bz>mt_SUOhjmRqv9
mt_IP0PTVfTXp>mt_QHKqckBdAk
mt_IP0PTVfTXp>mt_-r3B4FQyX3
mt_iQYPw8bMfN>mt_DLcEzmmj2r
mt_iQYPw8bMfN>mt_f67qGDhyfi
mt_iQYPw8bMfN>mt_mayItsxMUu
mt_IR8kIjZn_V>mt_bKlnc7dyVK
mt_IR8kIjZn_V>mt_bvxkT1nepy
mt_IR8kIjZn_V>mt_mmudyxf7bT
mt_IR8kIjZn_V>mt_szw1Ln490b
mt_islVn_P28Z>mt_22XbXTRq50
mt_islVn_P28Z>mt_z9jn9HogfE
mt_isojCL9yy->mt_aPBzD28_mT
mt_isojCL9yy->mt_WX30dzi4dt
mt__Itf4aQZUj>mt_FAXjFkgG6X
mt__Itf4aQZUj>mt_kDMKJ5Ztt6
mt__Itf4aQZUj>mt_wvcFlwOrDl
mt__Itf4aQZUj>mt_Xt1cRqaBOW
mt_iTjrKEdAOj>mt_ae-cHHFR76
mt_iTjrKEdAOj>mt_u3Y3Tb-G_n
mt_itldWmVItr>mt_islVn_P28Z
mt_itldWmVItr>mt_z9jn9HogfE
mt_IuHa5UI5od>mt_NSC3LT_-ch
mt_iv-BJS9W60>mt_w4wKFP3jud
mt_IwEOCN6bL1>mt_4MFUAsbx_6
mt_IwEOCN6bL1>mt_d-WZC2OyMB
mt_IwEOCN6bL1>mt_-V7EnqU7gG
mt_Iwg2diBSyW>mt_LhkP_KKIRS
mt_Iwg2diBSyW>mt_SeNxOZTHCN
mt_iWGnyUyN2j>mt_Ag9NSWJu-X
mt_iWGnyUyN2j>mt_HBcvu0UxYe
mt_iWGnyUyN2j>mt_kvrvpQris4
mt_iWGnyUyN2j>mt_wwdRhPyz6s
mt_iWGnyUyN2j>mt_YbX3LD0Eca
mt_IX37F4rNed>mt_2ESZh70NyS
mt_IX37F4rNed>mt_ukLvUD8DFA
mt_IY3KwGLZgk>mt_AylKwhbDWM
mt_IY3KwGLZgk>mt_brgde1Vx0P
mt_iycQEai3dK>mt_bKlnc7dyVK
mt_iycQEai3dK>mt_JednrdYqpt
mt_iycQEai3dK>mt_mwirOvigWD
mt_iYOcfzFqMw>mt_TMOzMCE17H
mt_iyovKgZC1q>mt_cdMlC7EpTJ
mt_iyovKgZC1q>mt_hbe_kdE_7C
mt_iyovKgZC1q>mt_hBZwbst0ow
mt_iyovKgZC1q>mt_jCy07DyBNU
mt_izien3ZX51>mt_aPBzD28_mT
mt_izien3ZX51>mt_kw7xmp68rU
mt_IzlVK0Eony>mt_83gRQ9OPkc
mt_IzQvs7k_sE>mt_nvdpxAJTBG
mt_J03RFlVdas>mt_cdMlC7EpTJ
mt_J03RFlVdas>mt_KwdjWEmMNo
mt_J03RFlVdas>mt_tedML_iu4Y
mt__J2BO4V95l>mt_0ewYhTSHtP
mt__J2BO4V95l>mt_Jd2aWEUJ9G
mt_j2idD_jq73>mt_ntqNLHsj5n
mt_j2idD_jq73>mt_wq-1OJ_8s5
mt_j32D5DZX7x>mt_OltpfaX7l6
mt_J339bO7qLe>mt_ALUrJpY0cZ
mt_j351evNNnB>mt_cU3LcEVkBQ
mt_J40cOn7VWn>mt_okUMpHsV-P
mt_J40cOn7VWn>mt_pu2mmK27UA
mt_J4j7d3iAfg>mt_c29FaCTNsx
mt_J4j7d3iAfg>mt_iFFKZd-Vgv
mt_J5cx6S_eT9>mt_B8JOz79O6t
mt_J5cx6S_eT9>mt_qzwQAOfurw
mt_j5YqQnN6xe>mt_2ESZh70NyS
mt_j5YqQnN6xe>mt_cdMlC7EpTJ
mt_j5YqQnN6xe>mt_VKW8lOcFaw
mt_j6ENpc8--_>mt_32B7xjUPwF
mt_j6ENpc8--_>mt_82KKv0Fca3
mt_j6ENpc8--_>mt_v5DyOEpbbr
mt_J6uccv2Bo4>mt_OnV_DTp5i8
mt_J6uccv2Bo4>mt_w4OYcWJs6H
mt_j8Pv3s7TZR>mt_i1kk9HDctI
mt_j8Pv3s7TZR>mt_Iwg2diBSyW
mt_j8Pv3s7TZR>mt_Ytd8XC3eQr
mt_jBQS-CicNn>mt_TdV9YGJEoY
mt_JBWMqZVO7S>mt_1dXhJp6qLJ
mt_JBWMqZVO7S>mt_1VSFoM44JU
mt_JBWMqZVO7S>mt_iycQEai3dK
mt_JBWMqZVO7S>mt_Wpvuz3mvBq
mt_JcfP1hWKa_>mt_1LFVPjdGg-
mt_JcfP1hWKa_>mt_Wx5m6mwkpj
mt_jCy07DyBNU>mt_A-FyLLLLzy
mt_jCy07DyBNU>mt_aivrWs6jrS
mt_jCy07DyBNU>mt_ebPelt-qAl
mt_jCy07DyBNU>mt_hbe_kdE_7C
mt_Jd2aWEUJ9G>mt_Amw5ikSSQI
mt_Jd2aWEUJ9G>mt_cJjnPjuvCU
mt_Jd2aWEUJ9G>mt_H8dEMH_wik
mt_Jd2aWEUJ9G>mt_q7zxOloj_L
mt_JdAnBKIDnw>mt_5OxKnrGEMP
mt_JdAnBKIDnw>mt_HZyUwycFvf
mt_JdAnBKIDnw>mt_PCX1jZZnf9
mt_JdAnBKIDnw>mt__qlBYNP62H
mt_JednrdYqpt>mt_BnabTHkNIp
mt_Jf8xcX4UTq>mt_4MFUAsbx_6
mt_Jf8xcX4UTq>mt_hdrMoiTgqu
mt_jgNB2752b9>mt_9NvuqZKNiV
mt_JH_6RpNWjr>mt_Ac7oMWhyPw
mt_JH_6RpNWjr>mt_EDgw64OmfA
mt_JH_6RpNWjr>mt_Yw1_4Nfsql
mt_jHgRQ4hR0g>mt_8jFSnXxqQD
mt_jHv4BgRK8B>mt_e4x3l2JeLI
mt_jIcgbCmziD>mt_aVZJhPbc_1
mt_jIcgbCmziD>mt_V6456X6pJE
mt_jIszRCO2ij>mt_2uHYdoxD0H
mt_jIszRCO2ij>mt_QR3vxbN1o4
mt_JivEBTD_KV>mt_h-z88yf9Pn
mt_JivEBTD_KV>mt_RhntJz7p_6
mt_JivEBTD_KV>mt_rqLMfiw61L
mt_JivEBTD_KV>mt_yCmYV9ruQu
mt_JiZ3H90Xg8>mt_6xj94tmpi-
mt_JiZ3H90Xg8>mt_RNeEF1JU4J
mt_JmMtZCifJB>mt_Gm12BzcCfX
mt_JmMtZCifJB>mt_URezjbU-6f
mt_-JnOhdei6F>mt_NVr4AhsvIq
mt_-JnOhdei6F>mt_XrvPx5kUfO
mt_jO0gHMk7Ti>mt_tX0R4-4WXy
mt_JpQUM1129q>mt_cxJRc15osy
mt_Jq0MjURrRC>mt_BhYJZUsErp
mt_Jq0MjURrRC>mt_frDIaXzWbx
mt_JSUGQ5Repv>mt_URTJbS3hhs
mt_JSUGQ5Repv>mt_Wyd-l-6H7G
mt_Jvg8X0N5u0>mt_4WaKWECpcv
mt_Jvg8X0N5u0>mt_jHgRQ4hR0g
mt_Jvg_r4yWaY>mt_2Um22lTBZV
mt_Jvg_r4yWaY>mt_akBotspaf2
mt_Jvg_r4yWaY>mt_EQQWKz03P8
mt_Jvg_r4yWaY>mt_X_aDUBh-HF
mt_jvJ35MmCvK>mt_XbGfVhfiUz
mt_Jvvh5P06NV>mt_y1n0Zwhoca
mt_JVVKT-_AD9>mt_Cqm8iy48UI
mt_JVVKT-_AD9>mt_ZhUuT__i2H
mt_jwElFY7Syd>mt_S9SKah-yi_
mt_jwElFY7Syd>mt_uUa6cgv8zV
mt_JwP9QFv6gQ>mt_MHaiUd2FLA
mt_JwP9QFv6gQ>mt_QqG6IdmTSE
mt_jY7uf0Cb7o>mt_aPBzD28_mT
mt_JyfLtl_nhw>mt_68pIoiiG4g
mt_JyfLtl_nhw>mt_AiWlJfvC3O
mt_JyfLtl_nhw>mt_PNSyfH56eQ
mt_K0mZxY2AM8>mt_EHuU1ZeUFA
mt_K0mZxY2AM8>mt_go5i87u2b9
mt_K0Y15w48SY>mt_hVpGOEz2kG
mt_K0Y15w48SY>mt_lxaM6iVpdr
mt_K1-HopEJAB>mt_X_aDUBh-HF
mt_k1HXbEwG8f>mt_6aJUzBYGNs
mt_k1HXbEwG8f>mt_AylKwhbDWM
mt_k2WE0-22-4>mt_cFltwUQi-d
mt_k2WE0-22-4>mt_LpSuPgL31x
mt_K3R0yaHVcx>mt_d8al9JcajP
mt_K3R0yaHVcx>mt_GzcJEVkNRn
mt_K3R0yaHVcx>mt_iQYPw8bMfN
mt_K5jM7vlVhA>mt_7rJM8eWUfw
mt_K5jM7vlVhA>mt_wQ89AEXhz3
mt_K6qtan847r>mt_kH1DzOPsXG
mt_K6qtan847r>mt_ofOGCQ7FWj
mt_k7VtbWdfDO>mt_wq-1OJ_8s5
mt_K8_RYIvrTV>mt_FNSeo9_T2Z
mt_K8_RYIvrTV>mt_RNRymbz5SO
mt_KA5j5OeGvw>mt_RhntJz7p_6
mt_KA5j5OeGvw>mt_Ytd8XC3eQr
mt_KaF0SQvaiu>mt_uhuxX8sg9f
mt_KbCCmLmxYN>mt_H6LlpWgEYS
mt_KbCCmLmxYN>mt_OlhMP7ShFT
mt_KB_Czd7RQH>mt_1VmTUxBrNd
mt_KB_Czd7RQH>mt_3qrCtdoVAU
mt_kCSy3Lsgme>mt_4bJiGiMPmy
mt_kCSy3Lsgme>mt_oAg79ju344
mt_kDKo4lxRKi>mt_7OJjLOl0fz
mt_kDKo4lxRKi>mt_O9dH94NFae
mt_kDMKJ5Ztt6>mt_doX1BhmFgk
mt_kDMKJ5Ztt6>mt_TqDq6jyOmL
mt_kdWoAel3Zl>mt_Vi4Vo5xs_g
mt_KFKUR_gBg_>mt_eiB3-6pu6a
mt_KFKUR_gBg_>mt_Xt1cRqaBOW
mt__kFxuAgs6d>mt_mdZ3nBWChW
mt_kgTN6yk4oE>mt_6oxQPNLHNv
mt_kgTN6yk4oE>mt_mmudyxf7bT
mt_kgTN6yk4oE>mt_pTz6u49fQt
mt_kgTN6yk4oE>mt_szw1Ln490b
mt_kH1DzOPsXG>mt_AzTrT5ySCx
mt_kH1DzOPsXG>mt__p5n8z5soJ
mt__KHQttMde3>mt_F978c32kDr
mt__KHQttMde3>mt_PvU3eoikev
mt_KhS7K1Mgrw>mt_FX4a2Q8XXN
mt_KhS7K1Mgrw>mt_nNNVrLqPW3
mt_KIG5FQI5fC>mt_enj1sMcfOT
mt_KiRn5lnRgj>mt_w2xiMNkyyX
mt_kJ4xXKL_nO>mt_8FwtdJzeDh
mt_kJ5wYzO8qC>mt_nyK25mNOeR
mt_kJ5wYzO8qC>mt_oIzycTBeE4
mt_kJ5wYzO8qC>mt_QCgbiVrwnp
mt_kJGCjnuelW>mt_s2mfRBoTal
mt_kJGCjnuelW>mt_THl9GLxwoL
mt_kKxbPHi5Db>mt_1m5ItPiwUK
mt_kKxbPHi5Db>mt_NPTjGJIyb3
mt_kLQOzZYrd5>mt_3qrCtdoVAU
mt_kLQOzZYrd5>mt_5mIcmKRCgA
mt_kLQOzZYrd5>mt_ATYLKt0je-
mt_kLQOzZYrd5>mt_FspV_imUGK
mt_kLQOzZYrd5>mt_tpT9brpI6D
mt_klyw-tdlhP>mt_mvXufozy2s
mt_KmPZ5diLEP>mt_ukLvUD8DFA
mt_KmPZ5diLEP>mt_xjl6AEhnjk
mt_kON8bYEHYl>mt_2OSTHTWDpa
mt_kON8bYEHYl>mt_m43jiOAOCt
mt_kOYw43NPzr>mt_7nduoLvoB1
mt_kOYw43NPzr>mt_kDKo4lxRKi
mt_kOYw43NPzr>mt_X4CJpPRxae
mt_Kr3IyA6m-O>mt_cFltwUQi-d
mt_Kr3IyA6m-O>mt_YzM5goBctT
mt_KRNU0IOKfO>mt_8QOeG3CuKc
mt_KRNU0IOKfO>mt_AB-TEMXSGJ
mt_KRNU0IOKfO>mt_kCSy3Lsgme
mt_KRNU0IOKfO>mt_w4OYcWJs6H
mt_KsKLVW_ssY>mt_go5i87u2b9
mt_KTSoXcO7OL>mt_VBl1T1sFCM
mt_KTSoXcO7OL>mt_YPSx5pbpVl
mt_k-V37x3zsF>mt_OltpfaX7l6
mt_kvrvpQris4>mt_9Y5-GjF2B0
mt_kvrvpQris4>mt_Iwg2diBSyW
mt_kVzAFMuFc4>mt__KHQttMde3
mt_kVzAFMuFc4>mt_OgJPbGkrYk
mt_kVzAFMuFc4>mt_UvNrOXny1i
mt_kw7xmp68rU>mt_sYpKWbq5ra
mt_kw7xmp68rU>mt_THl9GLxwoL
mt_KwdjWEmMNo>mt_i9rJbuFO3p
mt_KwdjWEmMNo>mt_Jvg8X0N5u0
mt_KYx0m4OyZv>mt_iTjrKEdAOj
mt_KYx0m4OyZv>mt_Z_Wu_77ybI
mt_L1469gt34A>mt_j7cer_Nmor
mt_L1469gt34A>mt_zexbopQjG0
mt_L1469gt34A>mt_zVLOm6U7bh
mt_l6OpmOKMuT>mt_m31_gPS8F1
mt_l6OpmOKMuT>mt_ytUG3yjCYt
mt_lAvS72LOUO>mt_LhkP_KKIRS
mt_lAvS72LOUO>mt_wRlf0g2MbB
mt_lAvS72LOUO>mt_wzUzVEBqJb
mt_Lb2ZnMdkYR>mt_C9ZfT-4cgn
mt_Lb2ZnMdkYR>mt_gtTl3R5buH
mt_lcf8lx-LkZ>mt_GBY8enpzO0
mt_lcf8lx-LkZ>mt_k7GOtslF-x
mt_lcf8lx-LkZ>mt_-p_xp4hMvh
mt_LCJNRaRXtW>mt_E_OryWIYkn
mt_lC_Q5mSL_I>mt_9L3NQqgqRd
mt_lC_Q5mSL_I>mt_jY7uf0Cb7o
mt_LE7nFEwS12>mt_S4G6GLKr1-
mt_lFiDFPkVmH>mt_33RrpbceZE
mt_lFiDFPkVmH>mt_LQt4vnKeB4
mt_lFiDFPkVmH>mt_q15w--Fb5H
mt_LH714Riydn>mt_lp3qyEujIv
mt_LH714Riydn>mt_TDUpy57QVM
mt_lHasFmgvnT>mt_v9uYnIY5-B
mt__LiAEHt9nk>mt_1z-gJBJFlM
mt__LiAEHt9nk>mt__AWSThGJ0d
mt__LiAEHt9nk>mt_ZpCcTU8j_o
mt_liIW336odh>mt_8H2kO4k2B9
mt_liIW336odh>mt_r8c43QB6wx
mt_lIs10UMkPG>mt_02DH7sGXCi
mt_lIs10UMkPG>mt_kvrvpQris4
mt_lIs10UMkPG>mt__MDiDU9Vck
mt_lIs10UMkPG>mt_nDAcXoPa0c
mt_lIs10UMkPG>mt_o8ciHks8t2
mt_LKagN9GJPX>mt_0_K-GrKQpd
mt_LKagN9GJPX>mt_bqL8DD1SbV
mt_LKagN9GJPX>mt_fkcxpeYP85
mt_LKagN9GJPX>mt_Gm12BzcCfX
mt_LKagN9GJPX>mt_KRNU0IOKfO
mt_LKagN9GJPX>mt_nRF_VRntrW
mt_LKagN9GJPX>mt_Qkewo5M3_c
mt_LKagN9GJPX>mt_rML9unnd9x
mt_LKagN9GJPX>mt_zCGwH1OQZa
mt_LkOMijDvL7>mt_4JpMXUIxeD
mt_LlMl2PbaZe>mt_kDMKJ5Ztt6
mt_LlMl2PbaZe>mt_QqG6IdmTSE
mt_lm0usBAF53>mt_yefw2CQT4x
mt_lMLeNLDRO8>mt_VfA4xo4kUv
mt_LMX-nZETLM>mt_82KKv0Fca3
mt_LMX-nZETLM>mt_86DyHo9zO3
mt_LMX-nZETLM>mt_FGCFUCqJBB
mt_lMz9nAs7VO>mt__h7hvT4tEb
mt_lMz9nAs7VO>mt_qeZYF6HZ4o
mt_lMz9nAs7VO>mt_yBJyCfhtem
mt_LN_g2b3d34>mt_uorNrPTh6U
mt_LN_g2b3d34>mt_VY3rBq8RyP
mt_LN_g2b3d34>mt_wq-1OJ_8s5
mt_lNGpnILM5C>mt_Ac7oMWhyPw
mt_LNYTNpJOGT>mt_f8n4txtLej
mt_loEMaQ8kFA>mt_H3ZDK0EYNV
mt_loEMaQ8kFA>mt_NzCNuABT3E
mt_loEMaQ8kFA>mt_-QY08-88rw
mt_lp3qyEujIv>mt_6eTZUwKQZr
mt_lp3qyEujIv>mt_GugVunb2lI
mt_LpSuPgL31x>mt_zuKAX6lcYR
mt_LPYPuSaxv_>mt_h_shhH-6DC
mt_LPYPuSaxv_>mt_JivEBTD_KV
mt_LPYPuSaxv_>mt_WtO50EZQkf
mt_LRzjbo1Fn6>mt_9EoS35vaYB
mt_LRzjbo1Fn6>mt_gTDqxYkLs9
mt_LRzjbo1Fn6>mt_lWqmKn5Jvr
mt_LRzjbo1Fn6>mt_UR5LvBeyF1
mt_LRzjbo1Fn6>mt_Wyd-l-6H7G
mt_lSFwVU7V9g>mt_8UL1opbJEt
mt_lSFwVU7V9g>mt_cM8YS6NXqi
mt_lSFwVU7V9g>mt_P0HBNfp46z
mt_lSFwVU7V9g>mt_szw1Ln490b
mt_lsO9O-_eZH>mt_m3-eXac3aP
mt_lsO9O-_eZH>mt_uycuqPaiJ1
mt_lsO9O-_eZH>mt_xYjD_kA70s
mt_LsY4-T2fU7>mt_KRNU0IOKfO
mt_LsY4-T2fU7>mt_nRF_VRntrW
mt_LsY4-T2fU7>mt_r8XnXwRA6g
mt_LTb0ZReMR2>mt_BI6oGIO-xM
mt_LTb0ZReMR2>mt_QH-Fs97twT
mt_lU-2aTRB9f>mt_wPgpMJ0-PA
mt_lU-2aTRB9f>mt_WsM4EmdOLe
mt_Lu4H4mbsqO>mt_IlyE-Sm8k5
mt_Lu4H4mbsqO>mt_TDUpy57QVM
mt_Lu4H4mbsqO>mt_TTzJTF-OkG
mt_Lu4H4mbsqO>mt_VXcua6-txq
mt_Lu4H4mbsqO>mt_wWlZoLQBR6
mt_Lu4H4mbsqO>mt_ZxdfRbwkKM
mt_lutxvMlkwS>mt_3v0VNkwquK
mt_LuwHnQItF_>mt_bjlY5TE1y-
mt_LuwHnQItF_>mt_PThM5P7Umd
mt_lvaSGHwvQ5>mt_AabJisinfi
mt_lvaSGHwvQ5>mt_gx6KQK5-Kx
mt_lvaSGHwvQ5>mt_VKW8lOcFaw
mt_lxaM6iVpdr>mt_efOeaGFyGM
mt_lxaM6iVpdr>mt_R4AY0LKxfl
mt_lxaM6iVpdr>mt_SH7QgFl8-v
mt_LxK9OKZQZX>mt_ph4xZVMiVq
mt_LxK9OKZQZX>mt_SFOSbVnrJ8
mt_LxK9OKZQZX>mt_VBl1T1sFCM
mt_lzCcQzPJZi>mt_6nqVnVdexe
mt_lzCcQzPJZi>mt_W_CNRTBgYR
mt_M1tnXqmYbn>mt_-F_Lv_apzH
mt_M1tnXqmYbn>mt_Gag_h98jWP
mt_M1tnXqmYbn>mt_JH_6RpNWjr
mt_m1W6nTQJ2b>mt_e8CZ7E5qW7
mt_m1W6nTQJ2b>mt__we2TDqnJx
mt_M2Gou3O6qT>mt_RTwmvr9R7V
mt_M2Gou3O6qT>mt_vpMDMbx4pc
mt_M2v1A9OEuM>mt_nvdpxAJTBG
mt_M2v1A9OEuM>mt_R2ccrI-nKD
mt_m31_gPS8F1>mt_oAg79ju344
mt_m3-eXac3aP>mt_-mw3JeIjhU
mt_m3-eXac3aP>mt_ntqNLHsj5n
mt_m43jiOAOCt>mt_2zJ1NrGgYm
mt_M5PPDJStGm>mt_WcfaSfVT33
mt_m6UaSmrQVG>mt_KsKLVW_ssY
mt_M7YrfAZk8u>mt_oNWXXAn3cn
mt_M8UQTURODF>mt_bKlnc7dyVK
mt_M8UQTURODF>mt_T8JGTJ-oNI
mt_mayItsxMUu>mt_1VSfm9yiLn
mt_mayItsxMUu>mt_e4x3l2JeLI
mt_Mb1JUJmnbX>mt_H4YZ1rSKP3
mt_Mb1JUJmnbX>mt_H8dEMH_wik
mt_Mb1JUJmnbX>mt_rpug2tkYhb
mt_Mb1JUJmnbX>mt_Y6P9y1Rz-u
mt_MBTVB-E-S7>mt_Mf-T-fYRLX
mt_MBTVB-E-S7>mt_Z_Wu_77ybI
mt_MCu_SNg_OW>mt_GDG9_SZmsO
mt_MCu_SNg_OW>mt_WX30dzi4dt
mt__MDiDU9Vck>mt_o8ciHks8t2
mt__MDiDU9Vck>mt_PJyCGJz5Hv
mt_mDp-1vlL3R>mt_9NQEiYLQA3
mt_mDp-1vlL3R>mt_a6AYrbb7x4
mt_mdZ3nBWChW>mt_bhwf_rDXQL
mt_mdZ3nBWChW>mt_NVr4AhsvIq
mt_MewIRdzpzz>mt_jY7uf0Cb7o
mt_MFfYcnv6Tv>mt_8OAGVdeTJ_
mt_MFfYcnv6Tv>mt_e4V6hvcuEJ
mt_MFfYcnv6Tv>mt_TdV9YGJEoY
mt_mFJ-2ZF6Tk>mt_6_O6THdEDK
mt_mFJ-2ZF6Tk>mt_6oxQPNLHNv
mt_Mf-T-fYRLX>mt_ahSqW_kK1b
mt_Mf-T-fYRLX>mt_Ge4Wtg6QMM
mt_Mf-T-fYRLX>mt_Qkewo5M3_c
mt_MHaiUd2FLA>mt_AQcVRBddko
mt_MHaiUd2FLA>mt_jY7uf0Cb7o
mt_MHaiUd2FLA>mt_lC_Q5mSL_I
mt_miGrca8zaS>mt_i1kk9HDctI
mt_miGrca8zaS>mt_O_UOTiMvT_
mt_miGrca8zaS>mt_pAuo9Op89t
mt_MJZA90uc6H>mt_eiB3-6pu6a
mt_mKAZTqItRG>mt_IntmJBg4VQ
mt_mKAZTqItRG>mt_QEr24lqzvH
mt_mKAZTqItRG>mt_Z3G_97fnha
mt_mkDqmejLMw>mt_enj1sMcfOT
mt_mkDqmejLMw>mt_Of-WsrRQ8B
mt_mKNmXqz_Oo>mt_Bztatrv-_v
mt_mKNmXqz_Oo>mt_EaWjCyn8W2
mt_ML5t7n2-U8>mt_AabJisinfi
mt_ML5t7n2-U8>mt_eiB3-6pu6a
mt_ML5t7n2-U8>mt_Jvg8X0N5u0
mt_ML5t7n2-U8>mt_liIW336odh
mt_MlD0gwLSw9>mt_VjxyJLtIbT
mt_MlmIrLb_7x>mt_DVSHx3YMkN
mt_MlmIrLb_7x>mt_E5YbLvMgLL
mt_MlmIrLb_7x>mt_furAIwoO9t
mt_mMMXD4v9Sh>mt_8UL1opbJEt
mt_mmudyxf7bT>mt_E7avIa-tcE
mt_mmudyxf7bT>mt_Qcp2d_kuta
mt_mmudyxf7bT>mt_szw1Ln490b
mt_mnEVZNkX3p>mt_KJeEeTutJI
mt_mnEVZNkX3p>mt_Qcp2d_kuta
mt_Mnodea7mG_>mt_Qcp2d_kuta
mt_Mnodea7mG_>mt_vnJEztczji
mt_Mnodea7mG_>mt_yGv8doDAmp
mt_MOY_2Cqalz>mt_LhkP_KKIRS
mt_Mp_CpVK6e->mt_KRNU0IOKfO
mt_mpktt3wj1M>mt_7D-vlii8F-
mt_mpktt3wj1M>mt_mkDqmejLMw
mt_mpS-JK_p_m>mt_jY7uf0Cb7o
mt_mpS-JK_p_m>mt_SrrsLiJkr3
mt_mQcWGh02no>mt_e4x3l2JeLI
mt_mQcWGh02no>mt_SrrsLiJkr3
mt_mQcWGh02no>mt_zMEvtigoM3
mt_mqgu72aCMz>mt_-3udyo6VyB
mt_mqgu72aCMz>mt_QhFEDyIwSO
mt_mqgu72aCMz>mt_YFS7JFk64p
mt_mqQ-DtH5m->mt_T8JGTJ-oNI
mt_MqqR7VUoz1>mt_KJeEeTutJI
mt_MqqR7VUoz1>mt_XjwUlmxdCT
mt_mquPi2IP-J>mt_i80I-1MLP2
mt_mquPi2IP-J>mt_V9SQS9gLFw
mt_mRCPP_Ab2W>mt_ytUG3yjCYt
mt_mr_Vk7FGzK>mt_s2mfRBoTal
mt_mTpV-0rtkO>mt_Be1A88GUpu
mt_mTpV-0rtkO>mt_EQQWKz03P8
mt_muxjw0fxxN>mt_v3Vz_Pgjjv
mt_muxjw0fxxN>mt_zVLOm6U7bh
mt_-mw3JeIjhU>mt_FGCFUCqJBB
mt_-mw3JeIjhU>mt_QEr24lqzvH
mt_-mw3JeIjhU>mt_u1-UfD0rTH
mt_mwirOvigWD>mt_R6YoRXkRxS
mt_mwirOvigWD>mt_Sa48W7KXB5
mt_MWXPiaTnEu>mt_oDU_8zMZjp
mt_MWXPiaTnEu>mt_QqG6IdmTSE
mt_M_xcaRcvSo>mt_oN7fI4d_kU
mt_My0OL6fhGL>mt__ab4knIaSL
mt_My0OL6fhGL>mt_RNRymbz5SO
mt_mydcMoa8gN>mt_cEQqskOaoo
mt_mydcMoa8gN>mt_p-8Hlf6_9k
mt_MyGblah2yY>mt_8RmpkDxT9L
mt_MyGblah2yY>mt_cFltwUQi-d
mt_MyGblah2yY>mt_vKcxX6iNOA
mt_mywsN77hGZ>mt_h0CVtqI2xo
mt_mywsN77hGZ>mt_HY8Yycu_rz
mt_mywsN77hGZ>mt_y1n0Zwhoca
mt_n0AlyLQwC9>mt_eMtV6tBSJm
mt_n0AlyLQwC9>mt_WtcFrxGOgw
mt_N1744276Zu>mt_9REmUc8r4D
mt_N1744276Zu>mt_TTzJTF-OkG
mt_N1744276Zu>mt_VP9yZJ1xeP
mt_N1744276Zu>mt_W_CNRTBgYR
mt__N55B7u7HD>mt_TcG90kS8nu
mt_n5_Jt4ExUd>mt_ph4xZVMiVq
mt_n5_Jt4ExUd>mt_ZL9qVVnpwN
mt_N5tciHU8cE>mt_gbTyzvnWzr
mt_N5tciHU8cE>mt_k7VtbWdfDO
mt_N5tiL3uIeq>mt_aVZJhPbc_1
mt_N5tiL3uIeq>mt_N5tciHU8cE
mt_N5tiL3uIeq>mt_T9IXrlxfx2
mt_n6GhzDPllD>mt_klyw-tdlhP
mt_N9zffZxuu5>mt_7D-vlii8F-
mt_N9zffZxuu5>mt_ay0qkGj0jg
mt_N9zffZxuu5>mt_enj1sMcfOT
mt_N9zffZxuu5>mt_Of-WsrRQ8B
mt_NaqEP8xDhZ>mt_doX1BhmFgk
mt_NaqEP8xDhZ>mt_ebPelt-qAl
mt_NckKLZ3uCE>mt_gv_uoHkdjR
mt_NckKLZ3uCE>mt_R6YoRXkRxS
mt_NckKLZ3uCE>mt_yhhprm7dZK
mt_NCrbQe0LdB>mt_AbnwmKD8oe
mt_NCrbQe0LdB>mt_nqM2OW0Qlm
mt_nDAcXoPa0c>mt_M5PPDJStGm
mt_nDAcXoPa0c>mt_o8ciHks8t2
mt_nDAcXoPa0c>mt_PJyCGJz5Hv
mt_nDAcXoPa0c>mt_sSQlLOnAow
mt_nDAcXoPa0c>mt_WBfj79OqXz
mt_ndGqFPWyen>mt_cFltwUQi-d
mt_ndGqFPWyen>mt_vKcxX6iNOA
mt_ndGqFPWyen>mt_Xp-rj46S2w
mt_NDZYiLvApW>mt_5S4byWDX6n
mt_NDZYiLvApW>mt_Bztatrv-_v
mt_NDZYiLvApW>mt_EaWjCyn8W2
mt_NDZYiLvApW>mt_H8OgKZbgGe
mt_NDZYiLvApW>mt_R7LEuZjTmx
mt_nFBLNoChD0>mt_18qkgxr_-T
mt_nIl1kKZHsk>mt_E5ju6kQSu3
mt_Nj32xtOhno>mt_cUMUYkDqZp
mt_Nj32xtOhno>mt_JdAnBKIDnw
mt_Nj32xtOhno>mt_lzCcQzPJZi
mt_Nj32xtOhno>mt_uzk7qs4KxE
mt_Nj32xtOhno>mt_XMz_ohNjYO
mt_nKS_vCYrg3>mt_w4wKFP3jud
mt_NLSfvB9vUl>mt_AQcVRBddko
mt_NLSfvB9vUl>mt_jY7uf0Cb7o
mt_NLSfvB9vUl>mt_QaYfeVL-0C
mt_nNDX_jZ-cb>mt_Iwg2diBSyW
mt_nNDX_jZ-cb>mt_SeNxOZTHCN
mt_NnlnxCx1DO>mt_5OxKnrGEMP
mt_NNNbPccwB4>mt_DA7-JYRvtP
mt_nNNVrLqPW3>mt_g_fkAqmz72
mt_nNYo5A-7Bl>mt_hi8cVycbwn
mt_nNYo5A-7Bl>mt_ZFwPZaDJ0_
mt_NoB20kVa4w>mt_Kr3IyA6m-O
mt_NoB20kVa4w>mt_ndGqFPWyen
mt_nOCPx5qw0Z>mt_ATYLKt0je-
mt_nOCPx5qw0Z>mt_ePXg_XyCKU
mt_nOCPx5qw0Z>mt_FnUJMXPUZX
mt_nOCPx5qw0Z>mt_XWSGuFW7It
mt_NP101Zl-4g>mt_6-MYToNZ39
mt_npRaYRhU2V>mt_mkDqmejLMw
mt_npRaYRhU2V>mt_mpktt3wj1M
mt_npRaYRhU2V>mt_Of-WsrRQ8B
mt_NPTjGJIyb3>mt_J6uccv2Bo4
mt_nqM2OW0Qlm>mt_rqLMfiw61L
mt_nqM2OW0Qlm>mt_z98J_Zg2L3
mt_nRF_VRntrW>mt_KsKLVW_ssY
mt_nRF_VRntrW>mt_Pl-nsjYGZ3
mt_nRksLqt-iR>mt_REwgr0d_ss
mt_nRksLqt-iR>mt_wUSbRt3-qw
mt_NSC3LT_-ch>mt_y1n0Zwhoca
mt_nTL-owFJTF>mt_d7XktBQPxm
mt_nTL-owFJTF>mt_XLP1IM3Qbb
mt_ntqNLHsj5n>mt_N8CpN1EJrP
mt_ntqNLHsj5n>mt_QEr24lqzvH
mt_ntxlccnYzB>mt_FZ_ixwU1p1
mt_nUnowllzaN>mt_NtJYlJdUe9
mt_nUnowllzaN>mt_vJO5Bxk4z-
mt_nvdpxAJTBG>mt_M5PPDJStGm
mt_NVr4AhsvIq>mt_e29VrLfmYt
mt_nwSWPTENmv>mt_83gRQ9OPkc
mt_nwSWPTENmv>mt_pJ5zsocdNx
mt_NYA50DFcOO>mt_jwElFY7Syd
mt_NYA50DFcOO>mt_R6YoRXkRxS
mt_NYA50DFcOO>mt_S9SKah-yi_
mt_NYA50DFcOO>mt_uUa6cgv8zV
mt_nyK25mNOeR>mt_7XcCG43ZZW
mt_nyK25mNOeR>mt_e8CZ7E5qW7
mt_nyK25mNOeR>mt_mB7DVai-Uf
mt_nyPMkeHlVJ>mt_5PgQB0QkWi
mt_nyPMkeHlVJ>mt_91f1XFvGZq
mt_nyPMkeHlVJ>mt_9P9o6d0Qm3
mt_nyPMkeHlVJ>mt_hp2qJ-QRBn
mt_nyPMkeHlVJ>mt_rDjtmDogJr
mt_nyPMkeHlVJ>mt_Y6P9y1Rz-u
mt_NYsz6QgaaE>mt_ChjMU2GDJa
mt_NYsz6QgaaE>mt_HZvTriQWTh
mt_NYsz6QgaaE>mt_r8XnXwRA6g
mt_NYsz6QgaaE>mt_zCGwH1OQZa
mt_nYU6x2E2T8>mt_ZhvwM6LMBL
mt_NZHFcEtTyI>mt_sDmrVCfzqt
mt_nZkL5-XjRX>mt_K5jM7vlVhA
mt_nZkL5-XjRX>mt_Lb2ZnMdkYR
mt_NzNLYDb9CZ>mt_-QY08-88rw
mt_NzNLYDb9CZ>mt_vFT_GbkP9m
mt_O2dS6gvClw>mt_Jq0MjURrRC
mt_O2dS6gvClw>mt_p_jxNLdus4
mt__o3TCmfomv>mt_N1744276Zu
mt__o3TCmfomv>mt_vFYFvgrPgD
mt_o7FJPDsHiW>mt_0sELh0MYWb
mt_o7FJPDsHiW>mt_6aJUzBYGNs
mt_O9dH94NFae>mt_aO018DkCun
mt_oajUvqAiBJ>mt_jvJ35MmCvK
mt_oajUvqAiBJ>mt_K6qtan847r
mt_oAK9GXSfqV>mt_WBfj79OqXz
mt_obF-6VYRya>mt_Hw70LI5xza
mt_obF-6VYRya>mt_TDUpy57QVM
mt_oB-L8EVdIP>mt_1LFVPjdGg-
mt_oB-L8EVdIP>mt_E1wR8IfCV6
mt_oB-L8EVdIP>mt_EygMHKs8Ed
mt_oB-L8EVdIP>mt_M7XhBBzYof
mt_oB-L8EVdIP>mt_OnV_DTp5i8
mt_oDlduFnemk>mt_QysgF57dxh
mt_oDU_8zMZjp>mt_aPBzD28_mT
mt_oDU_8zMZjp>mt_cChv2j_-Da
mt_of2GggtxFl>mt_1KCwbGvm1F
mt_of2GggtxFl>mt_N8CpN1EJrP
mt_ofOGCQ7FWj>mt_kH1DzOPsXG
mt_Of-WsrRQ8B>mt_enj1sMcfOT
mt_OgJPbGkrYk>mt_9-OHslmt1g
mt_OgJPbGkrYk>mt_BtMbZibZUj
mt_OgJPbGkrYk>mt_F978c32kDr
mt_OgJPbGkrYk>mt__KHQttMde3
mt_oH1XC8aQYn>mt_dpM1l5IOk6
mt_oH1XC8aQYn>mt_uQljqc0J5j
mt_ohUnzoI_nx>mt_FuVEZ1Ac9s
mt_OiDHqtLoln>mt_2DBPJ38iWl
mt_OiDHqtLoln>mt_6XnezHOcM3
mt_OiDHqtLoln>mt_9REmUc8r4D
mt_oiqsIP97V3>mt_XlyF294bPR
mt_oIzycTBeE4>mt_8RmpkDxT9L
mt_OJVkWvIaM_>mt_wRlf0g2MbB
mt_OkSJfrmFb_>mt_nvdpxAJTBG
mt_OkSJfrmFb_>mt_THl9GLxwoL
mt_okUMpHsV-P>mt_qzbgwaUQOA
mt_oL9s_bufDp>mt_dmNvjroCPT
mt_olFzbawexJ>mt_DbI1kNg_0R
mt_OlhMP7ShFT>mt_1KCwbGvm1F
mt_oLHXfLujmh>mt_v3Vz_Pgjjv
mt_oLjz18CxDg>mt_33RrpbceZE
mt_oLjz18CxDg>mt_sUVeVXzRuq
mt_OltpfaX7l6>mt_XeMZdf2Y9W
mt_OLwNsTI6C7>mt_h3vmvQW5Wa
mt_OLwNsTI6C7>mt_WZnwITSWr8
mt_OMmiuv9ZLH>mt_SdIWVjzopp
mt_on7FHCDmi->mt_iodbOOmEQs
mt_-OndzpVsrv>mt_q-1a86ydgU
mt_OnV_DTp5i8>mt__aHSZTm5k5
mt_OnV_DTp5i8>mt_l6OpmOKMuT
mt_oNWXXAn3cn>mt__7hXSTbu9s
mt_oNWXXAn3cn>mt_yR1moI5kX1
mt_o_p-3tCxiM>mt_09sySPqM9Z
mt_o_p-3tCxiM>mt_AYzE1EAvI0
mt_o_p-3tCxiM>mt_vKcxX6iNOA
mt_oqvJJKCJXw>mt_HFN1pGASpZ
mt_oqvJJKCJXw>mt_mDp-1vlL3R
mt_oqziWKry-L>mt_e4V6hvcuEJ
mt_oqziWKry-L>mt_qUGMyMYn9m
mt_oR6dwRj2Ll>mt_L1469gt34A
mt_oR6dwRj2Ll>mt_-vsLvsxp0L
mt_oR6dwRj2Ll>mt_zVLOm6U7bh
mt_Oru08pKlxd>mt_4i-FKXDDXh
mt_Oru08pKlxd>mt_p6frRFuxS6
mt_Oru08pKlxd>mt_YPSx5pbpVl
mt_OSfCeIeBak>mt_4IVWRAZoNC
mt_OSfCeIeBak>mt_K8DJzqbksM
mt_ot9rcUwBtK>mt_D4lyx0iYyB
mt_ot9rcUwBtK>mt_H8OgKZbgGe
mt_OtShuvs3x8>mt_x5ZrQMAZ5v
mt_OtShuvs3x8>mt_xVW5U41tbp
mt_O_UOTiMvT_>mt_klyw-tdlhP
mt_O_UOTiMvT_>mt_m1W6nTQJ2b
mt_O_UOTiMvT_>mt_QR3vxbN1o4
mt_O_UOTiMvT_>mt_VAWV_l7J0D
mt_O_UOTiMvT_>mt_WkKkb7W9Qd
mt_OUv-QXmW7_>mt_kLQOzZYrd5
mt_oVwNnjYPUY>mt_ujwtRoYJ34
mt_oVwNnjYPUY>mt_w4wKFP3jud
mt_OvyoRo47K->mt_dmNvjroCPT
mt_OyOYHlZ2_T>mt_8dstvf-KKb
mt_OyOYHlZ2_T>mt_klyw-tdlhP
mt_OyOYHlZ2_T>mt_nDAcXoPa0c
mt_OyOYHlZ2_T>mt_o8ciHks8t2
mt_OyOYHlZ2_T>mt_U_8iVFZuHH
mt_Oz8yNPNtub>mt_07Geg7LITa
mt_Oz8yNPNtub>mt_oNWXXAn3cn
mt_OzRZ89GrQW>mt_e4x3l2JeLI
mt_P0HBNfp46z>mt_8UL1opbJEt
mt_p1imGSFgJT>mt_aw0PldeT_L
mt_p1imGSFgJT>mt_UEe3MC5RZc
mt_-P1kdZhHbL>mt_NtJYlJdUe9
mt_p3tZiUaWAa>mt_tHtjfjjFrl
mt_p3tZiUaWAa>mt_yBJyCfhtem
mt__p5n8z5soJ>mt_XbGfVhfiUz
mt_p6frRFuxS6>mt_4i-FKXDDXh
mt_p6frRFuxS6>mt_auVZZEuXjs
mt_p6frRFuxS6>mt_YPSx5pbpVl
mt_p6MhZJYYPN>mt_Zks8xyInSG
mt_p-8Hlf6_9k>mt_dlm3NspUyy
mt_p-8Hlf6_9k>mt_gf4RUcACLg
mt_p-8Hlf6_9k>mt_nIl1kKZHsk
mt_pAcaehday5>mt_dmNvjroCPT
mt_Pau0aqLNgp>mt_ydtcIBwHB9
mt_pAuo9Op89t>mt_i1kk9HDctI
mt_pAuo9Op89t>mt_UGf6jICEhs
mt_pAuo9Op89t>mt_WkKkb7W9Qd
mt_pbuhUQJjtt>mt_cPZwlUk8Nd
mt_PCX1jZZnf9>mt_B1ATUEVNPz
mt_PCX1jZZnf9>mt_bEvMBUv4eG
mt_PdYlsA33jB>mt_f8n4txtLej
mt_PdYlsA33jB>mt_NS5t-Jzlh8
mt_PdYlsA33jB>mt_YbX3LD0Eca
mt_PetJM-AYz9>mt_ujwtRoYJ34
mt_PgsHGYJMH->mt_OvyoRo47K-
mt_PgsHGYJMH->mt_zuKAX6lcYR
mt_ph4xZVMiVq>mt__00ZSLnB7p
mt_ph4xZVMiVq>mt_SFOSbVnrJ8
mt_ph4xZVMiVq>mt_ydtcIBwHB9
mt_PhIZNl2230>mt_H1pAi4F_Oh
mt_phpn6KhCAv>mt_Qzbh-_v0Gq
mt_phpn6KhCAv>mt_RTwmvr9R7V
mt_PifbJOuXrG>mt_-2VNlwAR5z
mt_PifbJOuXrG>mt_gLy3ZgZWiN
mt_PifbJOuXrG>mt_qZro923zvz
mt_PifbJOuXrG>mt_SFOSbVnrJ8
mt_pis4novXWQ>mt_82KKv0Fca3
mt_pis4novXWQ>mt_HWYAspz-LK
mt_pis4novXWQ>mt_I65kFjWwnF
mt_pitjUcaAdy>mt_doVAdMqfJg
mt_pitjUcaAdy>mt_LuwHnQItF_
mt_pitjUcaAdy>mt_lzCcQzPJZi
mt_PiWZA8Z0ZJ>mt_K0mZxY2AM8
mt_pjfmCMMPjO>mt_jY7uf0Cb7o
mt_pjfmCMMPjO>mt_K5jM7vlVhA
mt_p_jxNLdus4>mt_BhYJZUsErp
mt_p_jxNLdus4>mt_EqXlZfB4jp
mt_p_jxNLdus4>mt_F978c32kDr
mt_p_jxNLdus4>mt_OgJPbGkrYk
mt_PJyCGJz5Hv>mt_4A7FYmvVhA
mt_PJyCGJz5Hv>mt_N8CpN1EJrP
mt_PJyCGJz5Hv>mt_o8ciHks8t2
mt_PL9VkDwXfh>mt_b7T-CjOYUR
mt_PL9VkDwXfh>mt_SXbZ3bC9z7
mt_Pl-nsjYGZ3>mt_1JFUNQDwAJ
mt_Pl-nsjYGZ3>mt_htAYR-iCFF
mt__pMF-Xb0TE>mt_e29VrLfmYt
mt_p-nbe0w_lf>mt_AR-K72OIIO
mt_p-nbe0w_lf>mt_MCu_SNg_OW
mt_p-nbe0w_lf>mt_q9EaJc2FP8
mt_PNSyfH56eQ>mt_4K1dr204Hi
mt_PNSyfH56eQ>mt_ePXg_XyCKU
mt_PNSyfH56eQ>mt_ESgc4YBw-a
mt_PNSyfH56eQ>mt_SoDP1fSQEB
mt_pOstrrS763>mt_phpn6KhCAv
mt_ppENoD8vf1>mt_cM8YS6NXqi
mt_ppENoD8vf1>mt_Fw0bbM1e_g
mt_ppENoD8vf1>mt_w2u9bXP9n7
mt_ppENoD8vf1>mt_xVW5U41tbp
mt_ppENoD8vf1>mt_zir5yyAzUB
mt_pPGaf8bR8r>mt_38d-k-dJPa
mt_pPGaf8bR8r>mt_OtShuvs3x8
mt_PPNDO7BUrY>mt_k2WE0-22-4
mt_PPNDO7BUrY>mt_kgTN6yk4oE
mt_PpWSHA-0kv>mt_OvyoRo47K-
mt_PpWSHA-0kv>mt_sYpKWbq5ra
mt_PpWSHA-0kv>mt_zuKAX6lcYR
mt_Psun-u_lPf>mt_nUnowllzaN
mt_PsylzZ9lHW>mt_Gag_h98jWP
mt_PThM5P7Umd>mt_oN7fI4d_kU
mt_pTz6u49fQt>mt_bj1YCgNWUx
mt_pTz6u49fQt>mt_C3eNLQJlgt
mt_pTz6u49fQt>mt_E7avIa-tcE
mt_pu2mmK27UA>mt_cxJRc15osy
mt_pu2mmK27UA>mt_OSfCeIeBak
mt_pu2mmK27UA>mt_QhLAeAlHI0
mt_PvU3eoikev>mt_4GiE83rJF_
mt_PvU3eoikev>mt_UvNrOXny1i
mt_pwo81ls_J->mt_v3Vz_Pgjjv
mt_pwo81ls_J->mt_V_wIdRZLsG
mt_pWwV_8OgXD>mt_50SdpkNH49
mt_pWwV_8OgXD>mt_5S4byWDX6n
mt_pWwV_8OgXD>mt_CBxOcjh69x
mt_pWwV_8OgXD>mt_NDZYiLvApW
mt_-p_xp4hMvh>mt_B3W5EfimJw
mt_-p_xp4hMvh>mt_GBY8enpzO0
mt_pyMD_SIiYO>mt_4A7FYmvVhA
mt_pyMD_SIiYO>mt_6eTZUwKQZr
mt_pyMD_SIiYO>mt_kJ5wYzO8qC
mt_pyMD_SIiYO>mt_SrrsLiJkr3
mt_pyMD_SIiYO>mt_zxST3MarI9
mt_PYPs2yD2sn>mt_3-ii06P4YS
mt_PYPs2yD2sn>mt_E1wR8IfCV6
mt_PZ909yPrEC>mt_nvdpxAJTBG
mt_PZ909yPrEC>mt_OvyoRo47K-
mt_q15w--Fb5H>mt_5l7iGkf1Tp
mt_q15w--Fb5H>mt_K0mZxY2AM8
mt_q15w--Fb5H>mt_LQt4vnKeB4
mt_q15w--Fb5H>mt_w2xiMNkyyX
mt_q-1a86ydgU>mt_kLQOzZYrd5
mt_q-1a86ydgU>mt_OUv-QXmW7_
mt_Q2Eud_PPz6>mt_-mw3JeIjhU
mt_Q2k3fSwyzQ>mt_3WMADSy0mA
mt_Q2k3fSwyzQ>mt_AvrQauS_zX
mt_Q2k3fSwyzQ>mt_F3ATPTCYm6
mt_q3vRl4dddK>mt_uTKgmWqSoI
mt_q7zxOloj_L>mt_95zxYqpP7m
mt_q7zxOloj_L>mt_O_UOTiMvT_
mt_q7zxOloj_L>mt_RKeheOL9uo
mt_q7zxOloj_L>mt_TDUpy57QVM
mt_q9EaJc2FP8>mt_18fK9sQdIz
mt_q9EaJc2FP8>mt_AQo4u7O4sM
mt_QaYfeVL-0C>mt_ehGS_uVSJv
mt_QaYfeVL-0C>mt_ewmuMMPAzP
mt_QB4qIGJIIj>mt_32B7xjUPwF
mt_QB4qIGJIIj>mt_GugVunb2lI
mt_QCgbiVrwnp>mt_OvyoRo47K-
mt_Qcsl1Z1x0l>mt_curkA82CmO
mt_Qcsl1Z1x0l>mt_dRLP8g0SAg
mt_Qcsl1Z1x0l>mt_sdmm_m60qX
mt_Qcsl1Z1x0l>mt_zCUIJLdK_s
mt_QCWWmDMYZR>mt_aFvsj35QzC
mt_QdMMLRYWhn>mt_BhYJZUsErp
mt_QdMMLRYWhn>mt_EqXlZfB4jp
mt_QDTO3GAgcq>mt_89riIKwGYp
mt_QDTO3GAgcq>mt_e4V6hvcuEJ
mt_QDTO3GAgcq>mt_oqziWKry-L
mt_QepALf3bin>mt_cq711F7ruL
mt_QepALf3bin>mt_RTwmvr9R7V
mt_QEr24lqzvH>mt_N8CpN1EJrP
mt_qgb76wHN2X>mt_Wa44s-f8Ws
mt_QhFEDyIwSO>mt_FX4a2Q8XXN
mt_QhFEDyIwSO>mt_i9rJbuFO3p
mt_QhFEDyIwSO>mt_vHzVa3SURC
mt_QhFEDyIwSO>mt_VUQNveSYjQ
mt_QH-Fs97twT>mt_yR1moI5kX1
mt_QHKqckBdAk>mt_dpM1l5IOk6
mt_QHKqckBdAk>mt_uQljqc0J5j
mt_QhLAeAlHI0>mt_cxJRc15osy
mt_QhLAeAlHI0>mt_E1wR8IfCV6
mt_qixeaiswFP>mt_L1469gt34A
mt_Qkewo5M3_c>mt_ahSqW_kK1b
mt_Qkewo5M3_c>mt_fhqVdj4BYr
mt_Qkewo5M3_c>mt_Pl-nsjYGZ3
mt_Qkl46lyris>mt_7hB8s5eOP1
mt_Qkl46lyris>mt_g4YSiOCS8g
mt_QKRYLwaOU8>mt_AN2kJE6I0s
mt_QKRYLwaOU8>mt_v0K6GRi4ZL
mt_QK-ZZb7UUN>mt_g_M4Vh_pK7
mt_QK-ZZb7UUN>mt_zPDDJLAl-J
mt__qlBYNP62H>mt_kgTN6yk4oE
mt__qlBYNP62H>mt_yNGrY9xJ8Y
mt_QNxFnxikCN>mt_2VR963szuk
mt_QNxFnxikCN>mt_Qcp2d_kuta
mt_QpmVikVaqY>mt_70Ys4i1AB1
mt_QpmVikVaqY>mt_cU3LcEVkBQ
mt_QqG6IdmTSE>mt_jY7uf0Cb7o
mt_QR3vxbN1o4>mt_8dstvf-KKb
mt_QrVF5n7vci>mt_obF-6VYRya
mt_QrVF5n7vci>mt_Y6P9y1Rz-u
mt_QtIAWOcoQT>mt_jwElFY7Syd
mt_QtIAWOcoQT>mt_S9SKah-yi_
mt_QU5R7Aajy9>mt__casygEB85
mt_QU5R7Aajy9>mt_ilPrU0cbtT
mt_QU5R7Aajy9>mt_lU-2aTRB9f
mt_qUGMyMYn9m>mt_3S10OOGPqu
mt_qw6mhOl-Qy>mt_T6nrrf2K43
mt_QwWo6an9N1>mt_edaoZRkK6M
mt_QwWo6an9N1>mt_z7AJZapsJj
mt_QxsoqVUt6u>mt_Ag9NSWJu-X
mt_QxsoqVUt6u>mt_FwI7q7DSIx
mt_QxsoqVUt6u>mt_mB7DVai-Uf
mt_QxsoqVUt6u>mt_wwdRhPyz6s
mt_QxsoqVUt6u>mt_YbX3LD0Eca
mt_Qxyikkkzam>mt_cB7hV8sw7X
mt_Qxyikkkzam>mt_gMSFymQlrW
mt_Qxyikkkzam>mt_IX37F4rNed
mt_Qxyikkkzam>mt_s6-6FYb5UQ
mt_Qxyikkkzam>mt_tn1rY9GbEZ
mt_Qxyikkkzam>mt_v5DyOEpbbr
mt_-QY08-88rw>mt_NzCNuABT3E
mt_-QY08-88rw>mt_vFT_GbkP9m
mt_QysgF57dxh>mt_h0CVtqI2xo
mt_QysgF57dxh>mt_u23IGDxOpk
mt_qzbgwaUQOA>mt_-gkJdxJUQT
mt_qzbgwaUQOA>mt_IzlVK0Eony
mt_qzbgwaUQOA>mt_pJ5zsocdNx
mt_Qzbh-_v0Gq>mt__ab4knIaSL
mt_Qzbh-_v0Gq>mt_RNRymbz5SO
mt_Qzbh-_v0Gq>mt_zrCyqhngYm
mt_qzGADV-NGe>mt_6w2g7aoPgz
mt_qzGADV-NGe>mt_PifbJOuXrG
mt_qZro923zvz>mt_6w2g7aoPgz
mt_qZro923zvz>mt_Oru08pKlxd
mt_qZro923zvz>mt_SFOSbVnrJ8
mt_qzwQAOfurw>mt_cU3LcEVkBQ
mt_qzwQAOfurw>mt_mKAZTqItRG
mt_qzwQAOfurw>mt_ntqNLHsj5n
mt_qzwQAOfurw>mt_TfOiog-ALs
mt_qzwQAOfurw>mt_u1-UfD0rTH
mt_r0VXbfAmsH>mt_xmmgAzxe5j
mt_r1hw-KenpK>mt_Qzbh-_v0Gq
mt_r1hw-KenpK>mt_uSUqTjOl8m
mt_R1xLS1c2Pg>mt_PThM5P7Umd
mt_R2ccrI-nKD>mt_8gy7uxRlF6
mt_-r3B4FQyX3>mt_44HkROUnzE
mt_-r3B4FQyX3>mt_FuVEZ1Ac9s
mt_-r3B4FQyX3>mt_JSUGQ5Repv
mt_R4AY0LKxfl>mt_i5_HnoFOYw
mt_R4AY0LKxfl>mt_RVK655t391
mt_R4AY0LKxfl>mt_SH7QgFl8-v
mt_R4AY0LKxfl>mt_snlqRCiA1R
mt_r6oKXpN0er>mt_oB-L8EVdIP
mt_r6oKXpN0er>mt_QH-Fs97twT
mt_r6oKXpN0er>mt_SZJ1mN7Vfk
mt_R6YoRXkRxS>mt_SwaNNdm_Ks
mt_R7LEuZjTmx>mt_fDoE-pL6Jv
mt_R7LEuZjTmx>mt_oLHXfLujmh
mt_R7LEuZjTmx>mt_v3Vz_Pgjjv
mt_r8c43QB6wx>mt_QysgF57dxh
mt_r8c43QB6wx>mt_Xt1cRqaBOW
mt_r8XnXwRA6g>mt_c29FaCTNsx
mt_r8XnXwRA6g>mt_u5HkSxZECM
mt_r8XnXwRA6g>mt_VhBH8wrFC6
mt_rbPioPELM1>mt_UKmtuAsSLN
mt_rbY77m8_s1>mt_ae-cHHFR76
mt_rCMdwG-YOE>mt_1PAWhRhpdg
mt_rCMdwG-YOE>mt_HJA2Oz-Zh1
mt_rCMdwG-YOE>mt_ifPDOYvUqm
mt_rDjtmDogJr>mt_7IFpDVNsmt
mt_rDjtmDogJr>mt_ChjMU2GDJa
mt_REwgr0d_ss>mt_vnJEztczji
mt_REwgr0d_ss>mt_wUSbRt3-qw
mt_rf23aL6KwH>mt_pitjUcaAdy
mt_rf23aL6KwH>mt_UMOjbmLcbM
mt_RFeVlw0QvX>mt_nvdpxAJTBG
mt_RFeVlw0QvX>mt_sYpKWbq5ra
mt_RhntJz7p_6>mt_h-z88yf9Pn
mt_RhntJz7p_6>mt_q7zxOloj_L
mt_RhntJz7p_6>mt_QR3vxbN1o4
mt_RhntJz7p_6>mt_UHQfb-n-w3
mt_RioBUxHz1X>mt_yBJyCfhtem
mt_RKeheOL9uo>mt_95zxYqpP7m
mt_RKeheOL9uo>mt_N8CpN1EJrP
mt_RKeheOL9uo>mt_O_UOTiMvT_
mt_RKeheOL9uo>mt_QaYfeVL-0C
mt_RKeheOL9uo>mt_XuHmIn2xje
mt_rkrG2w7WXI>mt_uTKgmWqSoI
mt_rkrG2w7WXI>mt_Wc6cOTQ1bA
mt_RlILL2sccX>mt_B3W5EfimJw
mt_rML9unnd9x>mt_-JnOhdei6F
mt_rML9unnd9x>mt_W4j7T_PnGH
mt_rML9unnd9x>mt_XG4RqUIXm8
mt_rML9unnd9x>mt_XrvPx5kUfO
mt_RNeEF1JU4J>mt_6xj94tmpi-
mt_RNeEF1JU4J>mt_cOknxrYhwL
mt_RNeEF1JU4J>mt_h_shhH-6DC
mt_RNeEF1JU4J>mt_iodbOOmEQs
mt_RNeEF1JU4J>mt_Mb1JUJmnbX
mt_RNRymbz5SO>mt_FIkqA0qhnj
mt_RNRymbz5SO>mt_SsS7GptD_o
mt_roAgL1rQRF>mt_9-OHslmt1g
mt_roAgL1rQRF>mt_BtMbZibZUj
mt_roinupb_7L>mt_0sELh0MYWb
mt_roinupb_7L>mt_bABr-c2DfV
mt_rOqo-8GeKt>mt_6aJUzBYGNs
mt_rpug2tkYhb>mt_6eTZUwKQZr
mt_rpug2tkYhb>mt_H4YZ1rSKP3
mt_rpug2tkYhb>mt_H8dEMH_wik
mt_rpug2tkYhb>mt_TU3BcLOgiV
mt_rQ2YJJi4uh>mt_GugVunb2lI
mt_rQ2YJJi4uh>mt__KHQttMde3
mt_rQ2YJJi4uh>mt_klyw-tdlhP
mt_rQ2YJJi4uh>mt_N8CpN1EJrP
mt_rQ2YJJi4uh>mt_V-ldQp56bF
mt_rqalOvjkj3>mt_z9jn9HogfE
mt_rqLMfiw61L>mt_35-DhMh_Yr
mt_rqLMfiw61L>mt_Ag9NSWJu-X
mt_rqLMfiw61L>mt_iWGnyUyN2j
mt_rTn43s8RNX>mt_MVovx37Xct
mt_rTn43s8RNX>mt_SwaNNdm_Ks
mt_RTwmvr9R7V>mt_CrGnpVjnk8
mt_RTwmvr9R7V>mt_vpMDMbx4pc
mt_Ruk2-lyGPZ>mt_E1wR8IfCV6
mt_Ruk2-lyGPZ>mt_JpQUM1129q
mt_RVK655t391>mt_1KkvzwYxbR
mt_RWUY7_IXvw>mt_9QzSnn8m80
mt_rxInpOQ74w>mt_9QzSnn8m80
mt_rxJ2O_9Lkr>mt_dknMcCqvoY
mt_rxJ2O_9Lkr>mt_RTwmvr9R7V
mt_RXnyhCRYXA>mt_jHgRQ4hR0g
mt_RXnyhCRYXA>mt_p-nbe0w_lf
mt_RXnyhCRYXA>mt_WsM4EmdOLe
mt_rymBfJmvFl>mt_LhkP_KKIRS
mt_s08-QxASd2>mt_FZ_ixwU1p1
mt_S2fP8rUwrl>mt_h3vmvQW5Wa
mt_s2mfRBoTal>mt_e8CZ7E5qW7
mt_s2mfRBoTal>mt_ghF3Vv6taM
mt_S3XMQOYt_D>mt_k-V37x3zsF
mt_s6-6FYb5UQ>mt_9lN0SpKlEH
mt_s6-6FYb5UQ>mt_DVSHx3YMkN
mt_s6-6FYb5UQ>mt_LMX-nZETLM
mt_S7CnyZCnxg>mt_wq-1OJ_8s5
mt_S7UTAhptLi>mt_9NQEiYLQA3
mt_S7UTAhptLi>mt_a6AYrbb7x4
mt_S7UTAhptLi>mt_OJVkWvIaM_
mt_sA0RvWXSYY>mt_HZvTriQWTh
mt_sA0RvWXSYY>mt_j7cj9eWN7w
mt_sA0RvWXSYY>mt_jc9k_HJQGd
mt_sA0RvWXSYY>mt_PrWc-HZzDl
mt_sA2OvTiech>mt_933BohS9BH
mt_sA2OvTiech>mt_Ii1hV4V5ql
mt_Sa48W7KXB5>mt_j7cer_Nmor
mt_Sa48W7KXB5>mt_zexbopQjG0
mt_Sa48W7KXB5>mt_zVLOm6U7bh
mt_saW7PxtPxw>mt_6W5zzDIGZH
mt_saW7PxtPxw>mt_E5YbLvMgLL
mt_sBcRdUfAzV>mt_bfhng6mOuy
mt_sBcRdUfAzV>mt_KJeEeTutJI
mt_sBcRdUfAzV>mt_yGv8doDAmp
mt_SbEaQnMQoD>mt_RgQxPddV8v
mt_SbEaQnMQoD>mt_SsS7GptD_o
mt_SBkTGjiZjZ>mt_4K1dr204Hi
mt_SBkTGjiZjZ>mt_W17Kbwm0-u
mt_scbDHJZZHK>mt_SrmHaJXKrX
mt_scBgiMKhG_>mt_klyw-tdlhP
mt_Sc_SorJhXW>mt_wfEfQuHOG-
mt_sdmm_m60qX>mt_FW9_8F52bw
mt_sdmm_m60qX>mt_ukLvUD8DFA
mt_sdmm_m60qX>mt_WzOyJFKDIu
mt_sDmrVCfzqt>mt_E1wR8IfCV6
mt_ShAptVcQR3>mt_hsN-YvCNQY
mt_sHJqh6UUya>mt_-bMnJcPJy8
mt_sHJqh6UUya>mt_vmQJAtAFuy
mt_sJyZW4qYUG>mt_O2dS6gvClw
mt_skYly2Qm01>mt_uhuxX8sg9f
mt_sMAcZW6vWM>mt_aFvsj35QzC
mt_sMAcZW6vWM>mt_E5KC4AnRLW
mt_sMAcZW6vWM>mt_rQ2YJJi4uh
mt_sMAcZW6vWM>mt_VEwM7ClYYE
mt_sMAcZW6vWM>mt_ZhUuT__i2H
mt_SmghasIvbT>mt_3y7xKP9MjU
mt_SmghasIvbT>mt_RKeheOL9uo
mt_SmghasIvbT>mt_TDUpy57QVM
mt_SmghasIvbT>mt_WtcFrxGOgw
mt__sMrmOv3bx>mt_jY7uf0Cb7o
mt__sMrmOv3bx>mt_NLSfvB9vUl
mt_snlqRCiA1R>mt_oDlduFnemk
mt_SoDP1fSQEB>mt_wPgpMJ0-PA
mt_SoDP1fSQEB>mt_XLP1IM3Qbb
mt_SqhXQhAEUf>mt_2VpdPjvewx
mt_SqhXQhAEUf>mt_5HV4mbgSGH
mt_sQpIV0-qY7>mt_oAg79ju344
mt_sQpIV0-qY7>mt_ytUG3yjCYt
mt_SrmHaJXKrX>mt_4uPnLieBPN
mt_SrrsLiJkr3>mt_cChv2j_-Da
mt_SrrsLiJkr3>mt_ewmuMMPAzP
mt_SsLWS_APM7>mt_a1FdAsRKOF
mt_SsLWS_APM7>mt_IfEgu0X449
mt_SsLWS_APM7>mt_k2WE0-22-4
mt_sSQlLOnAow>mt_mLPEMpYb_R
mt_SUOhjmRqv9>mt_fL1Xz8ostr
mt_SUOhjmRqv9>mt_VLu59hpQ4T
mt_sUVeVXzRuq>mt_AvrQauS_zX
mt_sUVOS2jH3J>mt_0MfpLj0Uhb
mt_sUVOS2jH3J>mt_yHQacItlhf
mt_svFa6_mjO_>mt_tAJH5BrpOx
mt_svFa6_mjO_>mt_xq3YHZ2zeR
mt_SwaNNdm_Ks>mt_auVZZEuXjs
mt_SXbZ3bC9z7>mt_ebPelt-qAl
mt_SXbZ3bC9z7>mt_HnKbuCliNS
mt_sXRHr7tfS5>mt_6eTZUwKQZr
mt_sXRHr7tfS5>mt_S0hzjAeLSK
mt_sXRHr7tfS5>mt_wwdRhPyz6s
mt_sXRHr7tfS5>mt_ZBMcX2oRor
mt_sYpKWbq5ra>mt_dmNvjroCPT
mt_SZJ1mN7Vfk>mt_guaaD6Dn2M
mt_SZJ1mN7Vfk>mt_QH-Fs97twT
mt_-SZU6cVB_->mt_u3Y3Tb-G_n
mt_sZXPK1FnRB>mt_N8CpN1EJrP
mt_sZXPK1FnRB>mt_yBJyCfhtem
mt_t06dHX2ZYw>mt_OlhMP7ShFT
mt_t0g2SlP404>mt_-c4Ca_nBzX
mt_t0g2SlP404>mt_IfEgu0X449
mt_t1JXeNgKcu>mt__KHQttMde3
mt__t4afSyZRm>mt_m1W6nTQJ2b
mt__t4afSyZRm>mt__we2TDqnJx
mt_T6nrrf2K43>mt_EqXlZfB4jp
mt_T6nrrf2K43>mt_FYK8m6eHQm
mt_T6nrrf2K43>mt_zBUcAPDRPM
mt_T76hKqXf0z>mt_OvyoRo47K-
mt_T76hKqXf0z>mt_QCgbiVrwnp
mt_T8JGTJ-oNI>mt_LRzjbo1Fn6
mt_T8JGTJ-oNI>mt_yrSdVrXrsF
mt_T9IXrlxfx2>mt_IdFxLz-UW9
mt_T9IXrlxfx2>mt_YQ64pzcLDl
mt_tAJH5BrpOx>mt_eiB3-6pu6a
mt_tAJH5BrpOx>mt_ML5t7n2-U8
mt_tAJH5BrpOx>mt_nTL-owFJTF
mt_tAtMET4EIU>mt_9XVFje6Tyr
mt_tAtMET4EIU>mt_QqG6IdmTSE
mt_-tcJeAhK5k>mt_J5cx6S_eT9
mt_TDUpy57QVM>mt_8dstvf-KKb
mt_TDUpy57QVM>mt_95zxYqpP7m
mt_TdV9YGJEoY>mt_qeZYF6HZ4o
mt_TdV9YGJEoY>mt_Y9XKzLrUAZ
mt_tedML_iu4Y>mt_oqziWKry-L
mt_tedML_iu4Y>mt_QDTO3GAgcq
mt_Te-ulgYMUd>mt_8QOeG3CuKc
mt_Te-ulgYMUd>mt_9EoS35vaYB
mt_Te-ulgYMUd>mt_bK84sPehyP
mt_Te-ulgYMUd>mt_OnV_DTp5i8
mt_TfOiog-ALs>mt_N8CpN1EJrP
mt_TfOiog-ALs>mt_QEr24lqzvH
mt_TgHxujL81r>mt_09sySPqM9Z
mt_tGZ2sMzMGz>mt_6aJUzBYGNs
mt_tGZ2sMzMGz>mt_IP0PTVfTXp
mt_THl9GLxwoL>mt_r0VXbfAmsH
mt_THl9GLxwoL>mt_xmmgAzxe5j
mt_thsY1ZesaU>mt_mB7DVai-Uf
mt_thsY1ZesaU>mt_mLPEMpYb_R
mt_ThTbUuNb3p>mt_3jmBpEepYX
mt_ThTbUuNb3p>mt_Ae56umVlTT
mt_ThTbUuNb3p>mt_Qcsl1Z1x0l
mt_ThTbUuNb3p>mt_zCUIJLdK_s
mt_tHtjfjjFrl>mt_FYK8m6eHQm
mt_tHtjfjjFrl>mt_QdMMLRYWhn
mt_tIi6L1n7kF>mt_Hqz5y_tWz2
mt_tIi6L1n7kF>mt_x2sWtfTeYT
mt_TiQbi027PE>mt_cChv2j_-Da
mt_TiQbi027PE>mt_Zx1xZM-RbX
mt_TKZefYXaVS>mt_mquPi2IP-J
mt_TlGhXAqC4p>mt_aulwq39aj8
mt_TlGhXAqC4p>mt_AVk2EmSULC
mt_TlLE4cZgOr>mt_jc9k_HJQGd
mt_Tls5qJ4p0L>mt_1wxwg782yX
mt_Tls5qJ4p0L>mt_h4abSktujo
mt_tMLsTPQHwF>mt_Oru08pKlxd
mt_tMLsTPQHwF>mt_q15w--Fb5H
mt_TMoHjMhRS2>mt_lMz9nAs7VO
mt_TMoHjMhRS2>mt_oIzycTBeE4
mt_TMoHjMhRS2>mt_U0waNfD8PB
mt_TMOzMCE17H>mt_AB-TEMXSGJ
mt_TMOzMCE17H>mt_hjJkBWruO6
mt_TMOzMCE17H>mt_-YYnLLIZh5
mt_tn1rY9GbEZ>mt_4-vfMgmCVB
mt_tn1rY9GbEZ>mt_hjtbA3g-Nn
mt_tn1rY9GbEZ>mt_uvILgZq9HN
mt_To9HdLy8vq>mt_MewIRdzpzz
mt_tpT9brpI6D>mt_2VpdPjvewx
mt_tpT9brpI6D>mt_ATYLKt0je-
mt_TqDq6jyOmL>mt_doX1BhmFgk
mt_TqDq6jyOmL>mt_W17Kbwm0-u
mt_tqgZH11cP5>mt_0Rx1ISxXFE
mt_tqgZH11cP5>mt_9gpUHWVKMR
mt_tqgZH11cP5>mt_RgQxPddV8v
mt_tQkCzRcWG7>mt_oR6dwRj2Ll
mt_TR2oTy9c2M>mt_BX4D8cCFtQ
mt_TR2oTy9c2M>mt_V9SQS9gLFw
mt_TTzJTF-OkG>mt_2GDBmKCJxs
mt_TTzJTF-OkG>mt_E5KC4AnRLW
mt_TTzJTF-OkG>mt_ukLvUD8DFA
mt_TTzJTF-OkG>mt_VXcua6-txq
mt_TTzJTF-OkG>mt_Y6P9y1Rz-u
mt_TU3BcLOgiV>mt_69hFD2NgGe
mt_TU3BcLOgiV>mt_H4YZ1rSKP3
mt_tX0R4-4WXy>mt_yHQacItlhf
mt_tXxxCFl32J>mt_AiWlJfvC3O
mt_tXxxCFl32J>mt_sUVeVXzRuq
mt_tXxxCFl32J>mt_Y9k86G8BBT
mt_tzMr83pS8v>mt_bPFToj0OhZ
mt_tzMr83pS8v>mt_K6qtan847r
mt_u0TeRwRII_>mt_BnabTHkNIp
mt_U0waNfD8PB>mt_THl9GLxwoL
mt_U0waNfD8PB>mt__YRJ23GuIK
mt_u1-UfD0rTH>mt_N8CpN1EJrP
mt_u1-UfD0rTH>mt_QEr24lqzvH
mt_u23IGDxOpk>mt_MFfYcnv6Tv
mt_u23IGDxOpk>mt_qeZYF6HZ4o
mt_u3OuIXqmAo>mt_37QCuGOxFe
mt_u3Y3Tb-G_n>mt_PiWZA8Z0ZJ
mt_u3Y3Tb-G_n>mt_XlyF294bPR
mt_U4cIBXVug4>mt_gtTl3R5buH
mt_u6SYiVx7FX>mt__p5n8z5soJ
mt_u6SYiVx7FX>mt_WRRv1ABECC
mt_u7Jxjjatkh>mt_18qkgxr_-T
mt_u7Jxjjatkh>mt_yBJyCfhtem
mt_U_8iVFZuHH>mt_QB4qIGJIIj
mt_U_8iVFZuHH>mt_Y6P9y1Rz-u
mt_U9sme87C32>mt__casygEB85
mt_-UAxilUtUt>mt_j7cj9eWN7w
mt_UcGn2hjhYU>mt_iFFKZd-Vgv
mt_udgPy5oAvR>mt_asRwlPZXC3
mt_udgPy5oAvR>mt_My0OL6fhGL
mt_udgPy5oAvR>mt_RNRymbz5SO
mt_uDJY0X0hgo>mt_9QzSnn8m80
mt_uDJY0X0hgo>mt_PsylzZ9lHW
mt_uDJY0X0hgo>mt_RVK655t391
mt_UEe3MC5RZc>mt_aw0PldeT_L
mt_UEe3MC5RZc>mt_FYK8m6eHQm
mt_uESbzWCZIq>mt_FX4a2Q8XXN
mt_uG2mjHFOlO>mt_OvyoRo47K-
mt_uG2mjHFOlO>mt_xmmgAzxe5j
mt_UGf6jICEhs>mt_SeNxOZTHCN
mt_UHQfb-n-w3>mt_uTKgmWqSoI
mt_U_HQXCnAaG>mt_T6nrrf2K43
mt_U_HQXCnAaG>mt_y8sicbhMci
mt_uhuxX8sg9f>mt_NtJYlJdUe9
mt_UjuriPLVgT>mt_33RrpbceZE
mt_UjuriPLVgT>mt_aulwq39aj8
mt_ujwtRoYJ34>mt_aVZJhPbc_1
mt_ujwtRoYJ34>mt_gZIo5oiBMt
mt_ukLvUD8DFA>mt_8-POYyg7GJ
mt_ukLvUD8DFA>mt_E5KC4AnRLW
mt_ukLvUD8DFA>mt_rQ2YJJi4uh
mt_ukLvUD8DFA>mt_VEwM7ClYYE
mt_ukLvUD8DFA>mt_WzOyJFKDIu
mt_UKmtuAsSLN>mt_ahSqW_kK1b
mt_UKmtuAsSLN>mt_Mf-T-fYRLX
mt_UKmtuAsSLN>mt_Pl-nsjYGZ3
mt_uM6q_KBWKy>mt_QEr24lqzvH
mt_UMOjbmLcbM>mt_bjlY5TE1y-
mt_UMOjbmLcbM>mt_Zy-CKUkq34
mt_UNzojLkNdm>mt_4m8BimI4G5
mt_UooUHC_V7U>mt_KJeEeTutJI
mt_UooUHC_V7U>mt_mnEVZNkX3p
mt_UooUHC_V7U>mt_Qcp2d_kuta
mt_UoqUPI_uNz>mt_68pIoiiG4g
mt_UoqUPI_uNz>mt_CyV7crZ8hl
mt_UoqUPI_uNz>mt_v0K6GRi4ZL
mt_uorNrPTh6U>mt_VY3rBq8RyP
mt_uorNrPTh6U>mt_wq-1OJ_8s5
mt_uoTBeyMhGm>mt_AVk2EmSULC
mt_uP9faJlnRq>mt_asRwlPZXC3
mt_Uq5vYqboCR>mt_jBQS-CicNn
mt_Uq5vYqboCR>mt_SH7QgFl8-v
mt_uQljqc0J5j>mt_BnabTHkNIp
mt_uQljqc0J5j>mt_dpM1l5IOk6
mt_uQljqc0J5j>mt_u0TeRwRII_
mt_UQnAFPs83F>mt_AKAtWEwpcj
mt_UQnAFPs83F>mt_I5j1ZWo2cn
mt_UR5LvBeyF1>mt_1wxwg782yX
mt_UR5LvBeyF1>mt_cM8YS6NXqi
mt_UR5LvBeyF1>mt_h4abSktujo
mt_URezjbU-6f>mt_go5i87u2b9
mt_URTJbS3hhs>mt_M7XhBBzYof
mt_URTJbS3hhs>mt_oB-L8EVdIP
mt_URTJbS3hhs>mt_uVaS12lN1i
mt_uSUqTjOl8m>mt_FNSeo9_T2Z
mt_uSUqTjOl8m>mt_zrCyqhngYm
mt_U_tJvy3cbB>mt_2b6CB0w3Yx
mt_U_tJvy3cbB>mt_MBTVB-E-S7
mt_UTnDKQkVX5>mt_B1zj1RwQ3a
mt_uuB3owTqNY>mt_bjlY5TE1y-
mt_uuB3owTqNY>mt_LuwHnQItF_
mt_uVaS12lN1i>mt_loYPGHJ8lm
mt_uvILgZq9HN>mt_0QJoKWABdC
mt_uvILgZq9HN>mt_4-vfMgmCVB
mt_uycuqPaiJ1>mt_ntqNLHsj5n
mt_uzk7qs4KxE>mt_FDKd7I79JZ
mt_uzk7qs4KxE>mt_vFYFvgrPgD
mt_v0K6GRi4ZL>mt_1hgck6ucII
mt_v0K6GRi4ZL>mt_Sc_SorJhXW
mt_V2lNzEex_a>mt_fhqVdj4BYr
mt_V2lNzEex_a>mt_Qkewo5M3_c
mt_v33BwiyRnd>mt_E5KC4AnRLW
mt_v33BwiyRnd>mt_zlSoIKPyId
mt_v5DyOEpbbr>mt_82KKv0Fca3
mt_v5DyOEpbbr>mt_86DyHo9zO3
mt_v5DyOEpbbr>mt_9P9o6d0Qm3
mt_v5DyOEpbbr>mt_QB4qIGJIIj
mt_v5DyOEpbbr>mt_QR3vxbN1o4
mt_v5yDTWEiyQ>mt_6eTZUwKQZr
mt_v5yDTWEiyQ>mt_TDUpy57QVM
mt_V6456X6pJE>mt_OltpfaX7l6
mt_v6CBCMuvz1>mt_0u3QNroZ34
mt_v6CBCMuvz1>mt_FZ_ixwU1p1
mt_v6CBCMuvz1>mt_hjJkBWruO6
mt_-V7EnqU7gG>mt_ebPelt-qAl
mt_-V7EnqU7gG>mt_VgOePicFYK
mt_V9SQS9gLFw>mt_7hB8s5eOP1
mt_V9SQS9gLFw>mt_i80I-1MLP2
mt_v9uYnIY5-B>mt_LQt4vnKeB4
mt_v9uYnIY5-B>mt_oLjz18CxDg
mt_v9uYnIY5-B>mt_ZhKuYCbXz1
mt_VA126P6Wp5>mt_cOknxrYhwL
mt_VA126P6Wp5>mt_oqvJJKCJXw
mt_vAP_A986IQ>mt_bqL8DD1SbV
mt_vAP_A986IQ>mt_m6UaSmrQVG
mt_vAP_A986IQ>mt_R6YoRXkRxS
mt_vauULTecMH>mt_82KKv0Fca3
mt_vauULTecMH>mt_nDAcXoPa0c
mt_VAWV_l7J0D>mt_mr_Vk7FGzK
mt_VAWV_l7J0D>mt_yJmvUCCym7
mt_VBl1T1sFCM>mt_YPSx5pbpVl
mt_VBl1T1sFCM>mt_ZL9qVVnpwN
mt_VEwM7ClYYE>mt_aFvsj35QzC
mt_VEwM7ClYYE>mt_E5KC4AnRLW
mt_VEwM7ClYYE>mt_mLPEMpYb_R
mt_VEwM7ClYYE>mt_sSQlLOnAow
mt_VEwM7ClYYE>mt_V-ldQp56bF
mt_VFsuftfvYM>mt_76SPWvdI7r
mt_VFsuftfvYM>mt_aPBzD28_mT
mt_vFT_GbkP9m>mt_Hah24nbToi
mt_vFT_GbkP9m>mt_NzCNuABT3E
mt_vFT_GbkP9m>mt_X_aDUBh-HF
mt_vFYFvgrPgD>mt_6nqVnVdexe
mt_vFYFvgrPgD>mt_8ad4U6msea
mt_VgOePicFYK>mt_09sySPqM9Z
mt_VgOePicFYK>mt_CBHwluE6Lp
mt_VhBH8wrFC6>mt_ylXdiVRAYv
mt_vHzVa3SURC>mt_KwdjWEmMNo
mt_Vi4Vo5xs_g>mt_NaqEP8xDhZ
mt_Vi4Vo5xs_g>mt_TqDq6jyOmL
mt_Vi4Vo5xs_g>mt_W17Kbwm0-u
mt_VI5kdtf28e>mt_Wyd-l-6H7G
mt_VI5kdtf28e>mt_X_aDUBh-HF
mt_VI5kdtf28e>mt_YB0qF5KX9C
mt_vJO5Bxk4z->mt_XirhnAB6Ye
mt_vJUa62bxeR>mt_Mnodea7mG_
mt_vJUa62bxeR>mt_sBcRdUfAzV
mt_vJUa62bxeR>mt_vnJEztczji
mt_VjxyJLtIbT>mt_mMMXD4v9Sh
mt_VjxyJLtIbT>mt_zh_RyesCgZ
mt_V_kAitNbLN>mt_bEvMBUv4eG
mt_V_kAitNbLN>mt_frDIaXzWbx
mt_V_kAitNbLN>mt_iFkd0CTwlA
mt_VKW8lOcFaw>mt_AabJisinfi
mt_VKW8lOcFaw>mt_ebPelt-qAl
mt_VKW8lOcFaw>mt_gx6KQK5-Kx
mt_V-ldQp56bF>mt_N8CpN1EJrP
mt_V-ldQp56bF>mt_OgJPbGkrYk
mt_V-ldQp56bF>mt_ZhvwM6LMBL
mt_VLu59hpQ4T>mt_oL9s_bufDp
mt_vmQJAtAFuy>mt_xAf2bu9wYK
mt_vmQJAtAFuy>mt_Zt30Gxi-qp
mt_VMS3kDQ8sA>mt_0QJoKWABdC
mt_VMS3kDQ8sA>mt_ntqNLHsj5n
mt_vmW2cb5c7A>mt_MWXPiaTnEu
mt_vmW2cb5c7A>mt_XLP1IM3Qbb
mt_VP9yZJ1xeP>mt_6nqVnVdexe
mt_VP9yZJ1xeP>mt_MlD0gwLSw9
mt_VP9yZJ1xeP>mt_S9SKah-yi_
mt_vpMDMbx4pc>mt_CrGnpVjnk8
mt_vpMDMbx4pc>mt_SbEaQnMQoD
mt_-vsLvsxp0L>mt_v3Vz_Pgjjv
mt_VtqvUORa8K>mt_ZBMcX2oRor
mt_vuNjYx3qOy>mt_AiWlJfvC3O
mt_vuNjYx3qOy>mt_Q2k3fSwyzQ
mt_VUQNveSYjQ>mt_jHgRQ4hR0g
mt_VUQNveSYjQ>mt_RXnyhCRYXA
mt_VVn1IXjkzn>mt_U9sme87C32
mt_VVx0hPPSKi>mt_cU3LcEVkBQ
mt_VVx0hPPSKi>mt_EbiGRVK8uR
mt_VVx0hPPSKi>mt_j351evNNnB
mt_VVx0hPPSKi>mt_X1L9DoUwjF
mt_V_wIdRZLsG>mt_oLHXfLujmh
mt_V_wIdRZLsG>mt_v3Vz_Pgjjv
mt_VXcua6-txq>mt_WzOyJFKDIu
mt_vXRzMbiPff>mt_M2v1A9OEuM
mt_VY3rBq8RyP>mt_mB7DVai-Uf
mt_w2A8D76ymp>mt_Jvg_r4yWaY
mt_w2A8D76ymp>mt_mTpV-0rtkO
mt_w2u9bXP9n7>mt_4bJiGiMPmy
mt_w2u9bXP9n7>mt_ytUG3yjCYt
mt_w2xiMNkyyX>mt_fI-8iqf_Id
mt_w2xiMNkyyX>mt_u3Y3Tb-G_n
mt_W4j7T_PnGH>mt_dSeFrAWE4v
mt_W4j7T_PnGH>mt_-JnOhdei6F
mt_W4j7T_PnGH>mt_QtIAWOcoQT
mt_w4nSIDhIgC>mt_Ag9NSWJu-X
mt_w4nSIDhIgC>mt_QxsoqVUt6u
mt_w4OYcWJs6H>mt_OnV_DTp5i8
mt_w4OYcWJs6H>mt_sQpIV0-qY7
mt_w4OYcWJs6H>mt_Wyd-l-6H7G
mt_w4wKFP3jud>mt_aFvsj35QzC
mt_w4wKFP3jud>mt_QCWWmDMYZR
mt_w4wKFP3jud>mt_r8XnXwRA6g
mt_W5euSyU2sO>mt_FNSeo9_T2Z
mt_W5euSyU2sO>mt_K8_RYIvrTV
mt_W5euSyU2sO>mt_tzMr83pS8v
mt_w5HzPpOUmj>mt_LxK9OKZQZX
mt_w5HzPpOUmj>mt_XSp-S0wter
mt_w6MxaaoMXZ>mt_Lb2ZnMdkYR
mt_w6MxaaoMXZ>mt_WX30dzi4dt
mt_w83U-_noVR>mt_Sc_SorJhXW
mt_W8Eq3CqWJf>mt_AVk2EmSULC
mt_Wa44s-f8Ws>mt_vJO5Bxk4z-
mt_WBdHkc2HTf>mt_hVpGOEz2kG
mt_WBdHkc2HTf>mt_vHzVa3SURC
mt_WBdHkc2HTf>mt_z5iwdZyeDr
mt_wB-GBDkoNr>mt_3y7xKP9MjU
mt_wB-GBDkoNr>mt_CBHwluE6Lp
mt_wB-GBDkoNr>mt_TqDq6jyOmL
mt_Wc6cOTQ1bA>mt_UHQfb-n-w3
mt_Wc6cOTQ1bA>mt_uTKgmWqSoI
mt_W_CNRTBgYR>mt_H1pAi4F_Oh
mt__we2TDqnJx>mt_e8CZ7E5qW7
mt__we2TDqnJx>mt_ghF3Vv6taM
mt_wE7-Gs9ENL>mt_6oxQPNLHNv
mt_wE7-Gs9ENL>mt_sBcRdUfAzV
mt_wfEfQuHOG->mt_Z_Wu_77ybI
mt_WfrE_4r-kY>mt_4m8BimI4G5
mt_wf-SJhZ1kC>mt_auVZZEuXjs
mt_wGxq92Na5g>mt_sMAcZW6vWM
mt_wGxq92Na5g>mt_yHQacItlhf
mt_wh3UqnWsa7>mt_GRWwTDZ3wD
mt_wh3UqnWsa7>mt_HhuSDxwDNM
mt_wHN14Unk7h>mt_R7LEuZjTmx
mt_wHN14Unk7h>mt_v3Vz_Pgjjv
mt_WkKkb7W9Qd>mt_8dstvf-KKb
mt_WkKkb7W9Qd>mt_dmNvjroCPT
mt_WkKkb7W9Qd>mt_mLPEMpYb_R
mt_WkKkb7W9Qd>mt_OvyoRo47K-
mt_WkKkb7W9Qd>mt_S4G6GLKr1-
mt_WKxX-b86Vr>mt_82KKv0Fca3
mt_WKxX-b86Vr>mt_91f1XFvGZq
mt_WNBHZ1d94L>mt_0B64gfJf7j
mt_WNBHZ1d94L>mt_6xsEXxKdUX
mt_wPgpMJ0-PA>mt_LlMl2PbaZe
mt_wPgpMJ0-PA>mt_lNGpnILM5C
mt_Wpvuz3mvBq>mt_1VSFoM44JU
mt_wq-1OJ_8s5>mt_mB7DVai-Uf
mt_wq-1OJ_8s5>mt_N8CpN1EJrP
mt_wq-1OJ_8s5>mt_u1-UfD0rTH
mt_wq-1OJ_8s5>mt_YXVQaufkKO
mt_wQ89AEXhz3>mt_HhuSDxwDNM
mt_wQ89AEXhz3>mt_IzQvs7k_sE
mt_Wr6DDgr_kH>mt_BI6oGIO-xM
mt_WRlJ0-hAOG>mt_Eehl12cSnN
mt_WRRv1ABECC>mt_XbGfVhfiUz
mt_WsM4EmdOLe>mt_MCu_SNg_OW
mt_WsM4EmdOLe>mt_XLP1IM3Qbb
mt_WtcFrxGOgw>mt_GzcJEVkNRn
mt_WtcFrxGOgw>mt_wE7-Gs9ENL
mt_WtIFJSCQIT>mt_8H2kO4k2B9
mt_WtIFJSCQIT>mt_liIW336odh
mt_WtO50EZQkf>mt_JiZ3H90Xg8
mt_WtO50EZQkf>mt_zIzJGkaj0Q
mt_Wu-ftkzoiE>mt_BLQ2_OXPod
mt_Wu-ftkzoiE>mt_e29VrLfmYt
mt_Wu-ftkzoiE>mt_NVr4AhsvIq
mt_wUSbRt3-qw>mt_vJUa62bxeR
mt_wUSbRt3-qw>mt_vnJEztczji
mt_wUyAZJikAA>mt_ntqNLHsj5n
mt_wUyAZJikAA>mt_uycuqPaiJ1
mt_wvcFlwOrDl>mt_32B7xjUPwF
mt_wwdRhPyz6s>mt_mB7DVai-Uf
mt_wwdRhPyz6s>mt_n6GhzDPllD
mt__wWHVvqMWb>mt_6EfevRyeFW
mt__wWHVvqMWb>mt_iYOcfzFqMw
mt__wWHVvqMWb>mt_olFzbawexJ
mt_wWlZoLQBR6>mt_2GDBmKCJxs
mt_wWlZoLQBR6>mt_hbe_kdE_7C
mt_wWlZoLQBR6>mt_TTzJTF-OkG
mt_wWlZoLQBR6>mt_VXcua6-txq
mt_wWlZoLQBR6>mt_ZxdfRbwkKM
mt_wWpa5fFDZP>mt_URTJbS3hhs
mt_wWpa5fFDZP>mt_WNBHZ1d94L
mt_WX30dzi4dt>mt_GDG9_SZmsO
mt_WX30dzi4dt>mt_HhuSDxwDNM
mt_WX30dzi4dt>mt_wQ89AEXhz3
mt_Wx5m6mwkpj>mt_-0cjwyYhce
mt_Wx5m6mwkpj>mt_x5ZrQMAZ5v
mt_WXW0hjNhph>mt_M5PPDJStGm
mt_WXW0hjNhph>mt_nvdpxAJTBG
mt_Wyd-l-6H7G>mt_cM8YS6NXqi
mt_Wyd-l-6H7G>mt_EygMHKs8Ed
mt_Wyd-l-6H7G>mt_Fw0bbM1e_g
mt_wzAZ8qFDc4>mt_UQnAFPs83F
mt_wzAZ8qFDc4>mt_VAWV_l7J0D
mt_Wzj1RETm9A>mt_olFzbawexJ
mt_Wzj1RETm9A>mt_w2A8D76ymp
mt_WZnwITSWr8>mt_saW7PxtPxw
mt_WZnwITSWr8>mt_y8sicbhMci
mt_WzOyJFKDIu>mt_6-MYToNZ39
mt_WzOyJFKDIu>mt_f_dMmvzxwo
mt_wzUzVEBqJb>mt_wRlf0g2MbB
mt_X0Tr8IYaEd>mt_hbe_kdE_7C
mt_X0Tr8IYaEd>mt_QrVF5n7vci
mt_X1L9DoUwjF>mt_j351evNNnB
mt_x2sWtfTeYT>mt_dmFnJzxKwz
mt_x2sWtfTeYT>mt_Hqz5y_tWz2
mt_X4CJpPRxae>mt_z9jn9HogfE
mt_X5cypSGoGU>mt_jHgRQ4hR0g
mt_x5ZrQMAZ5v>mt_-0cjwyYhce
mt_X7Tu94-a2m>mt_HBcvu0UxYe
mt_X7Tu94-a2m>mt_iWGnyUyN2j
mt_x8TshvbbQT>mt_fR0UtsSREU
mt_x8TshvbbQT>mt_M5PPDJStGm
mt_xACS3rWWDp>mt_g3W0mdADVu
mt_xACS3rWWDp>mt_-hTTat0mBR
mt_X_aDUBh-HF>mt_4i-FKXDDXh
mt_X_aDUBh-HF>mt_akBotspaf2
mt_X_aDUBh-HF>mt_DA7-JYRvtP
mt_X_aDUBh-HF>mt_VBl1T1sFCM
mt_xAf2bu9wYK>mt_14T5yPXUq_
mt_xAf2bu9wYK>mt_4K1dr204Hi
mt_xAf2bu9wYK>mt_ATYLKt0je-
mt_xAG0aMeAIN>mt_kgTN6yk4oE
mt_xAG0aMeAIN>mt_Lu4H4mbsqO
mt_xAG0aMeAIN>mt_Qxyikkkzam
mt_xAG0aMeAIN>mt_wWlZoLQBR6
mt_xE_b3JiDZU>mt_2OSTHTWDpa
mt_xE_b3JiDZU>mt_s08-QxASd2
mt_XeMZdf2Y9W>mt_1KCwbGvm1F
mt_xfwv0M83mJ>mt_8H2kO4k2B9
mt_xfwv0M83mJ>mt_gxCIASSezX
mt_xfwv0M83mJ>mt_mywsN77hGZ
mt_XfyqXLqzpx>mt_3fwYu7imd4
mt_XfyqXLqzpx>mt_vmQJAtAFuy
mt_XG4RqUIXm8>mt_BLQ2_OXPod
mt_XG4RqUIXm8>mt_QtIAWOcoQT
mt_XG4RqUIXm8>mt_S9SKah-yi_
mt_xhoOWnhtHq>mt_FHIAv6dfhU
mt_XirhnAB6Ye>mt_f8n4txtLej
mt_XirhnAB6Ye>mt_Hw70LI5xza
mt_XirhnAB6Ye>mt_klyw-tdlhP
mt_XirhnAB6Ye>mt_S4G6GLKr1-
mt_xjl6AEhnjk>mt_5n-O41lUgn
mt_xjl6AEhnjk>mt_9NQEiYLQA3
mt_xjl6AEhnjk>mt_GLY3R3YSlf
mt_xjl6AEhnjk>mt_zlSoIKPyId
mt_XjwUlmxdCT>mt_KJeEeTutJI
mt_XjwUlmxdCT>mt_yGv8doDAmp
mt_XK7NYt61cO>mt_y8sicbhMci
mt_xkn2sf93WJ>mt_tXxxCFl32J
mt_xkn2sf93WJ>mt_vuNjYx3qOy
mt_XL2gqdKJfu>mt_-0cjwyYhce
mt_XL2gqdKJfu>mt_BI6oGIO-xM
mt_XL2gqdKJfu>mt_xVW5U41tbp
mt_x_Lg4RASVU>mt_p1imGSFgJT
mt_x_Lg4RASVU>mt_T6nrrf2K43
mt_XLP1IM3Qbb>mt_q9EaJc2FP8
mt_XlyF294bPR>mt_PiWZA8Z0ZJ
mt_xmmgAzxe5j>mt_dmNvjroCPT
mt_xmmgAzxe5j>mt_fR0UtsSREU
mt_xMt1TLTs-->mt_5NwqN6pf_A
mt_xMt1TLTs-->mt_JwP9QFv6gQ
mt_XMz_ohNjYO>mt_14F_x1Xwwp
mt_XMz_ohNjYO>mt_cUMUYkDqZp
mt_XNmGwNggdU>mt__casygEB85
mt_XNmGwNggdU>mt_Gag_h98jWP
mt_XNmGwNggdU>mt_RVK655t391
mt_XnRhhEqJLJ>mt_sMAcZW6vWM
mt_xppl18avyY>mt__h7hvT4tEb
mt_xppl18avyY>mt_yqAL6O5i_v
mt_xPqczp7zPX>mt_aPBzD28_mT
mt_xPqczp7zPX>mt_izien3ZX51
mt_Xp-rj46S2w>mt_hyvHv2BCwb
mt_Xp-rj46S2w>mt_xACS3rWWDp
mt_XrvPx5kUfO>mt_bhwf_rDXQL
mt_XrvPx5kUfO>mt_-G6erQvLig
mt_XrvPx5kUfO>mt_jwElFY7Syd
mt_xSgAgg9Ej_>mt_UcGn2hjhYU
mt_xsk3iuNVVI>mt_OlhMP7ShFT
mt_XSp-S0wter>mt_LxK9OKZQZX
mt_XSp-S0wter>mt_PifbJOuXrG
mt_XSp-S0wter>mt_rbY77m8_s1
mt_xSs0xAd6i1>mt_JSUGQ5Repv
mt_xSs0xAd6i1>mt_URTJbS3hhs
mt_XSXnTQoQ4l>mt_Cg8VPguS_V
mt_XSXnTQoQ4l>mt_eKJG-0eC6D
mt_XSXnTQoQ4l>mt_fmm-P17Vka
mt_Xt1cRqaBOW>mt_sBcRdUfAzV
mt_Xt1cRqaBOW>mt_zuOGOGFAKb
mt_xT6jPzyj92>mt_j7cer_Nmor
mt_XuHmIn2xje>mt_SrrsLiJkr3
mt_XuHmIn2xje>mt_yTWxkzzoOZ
mt_XV0B4kWwqL>mt_M5PPDJStGm
mt_XV0B4kWwqL>mt_x8TshvbbQT
mt_xVW5U41tbp>mt_-0cjwyYhce
mt_xWg0lI_gG4>mt_e4x3l2JeLI
mt_xWg0lI_gG4>mt_skYly2Qm01
mt_XWSGuFW7It>mt_ATYLKt0je-
mt_XWSGuFW7It>mt_FHIAv6dfhU
mt_XWSGuFW7It>mt_FnUJMXPUZX
mt_XWSGuFW7It>mt_FspV_imUGK
mt_XxgU_91AXg>mt_-0cjwyYhce
mt_XxgU_91AXg>mt_xVW5U41tbp
mt_xYjD_kA70s>mt_j2idD_jq73
mt_xYjD_kA70s>mt_wq-1OJ_8s5
mt_xZvDCYA5Ae>mt_GDG9_SZmsO
mt_y1n0Zwhoca>mt_6xNmQLzuqm
mt_y1XCVsIelg>mt_FHIAv6dfhU
mt_Y2WcY2lOTK>mt_5l7iGkf1Tp
mt_Y2WcY2lOTK>mt_w2xiMNkyyX
mt_Y6P9y1Rz-u>mt_6eTZUwKQZr
mt_y8sicbhMci>mt_tHtjfjjFrl
mt_Y9k86G8BBT>mt_AvrQauS_zX
mt_Y9k86G8BBT>mt_GBY8enpzO0
mt_Y9k86G8BBT>mt_k7GOtslF-x
mt_Y9k86G8BBT>mt_-p_xp4hMvh
mt_Y9XKzLrUAZ>mt_-hTTat0mBR
mt_Y9XKzLrUAZ>mt_qeZYF6HZ4o
mt_y-BuQAfw4B>mt_2OtRUM_0zW
mt_y-BuQAfw4B>mt_K0Y15w48SY
mt_y-BuQAfw4B>mt_XWSGuFW7It
mt_YbX3LD0Eca>mt_mB7DVai-Uf
mt_YbX3LD0Eca>mt_NS5t-Jzlh8
mt_yCmYV9ruQu>mt_h-z88yf9Pn
mt_yCmYV9ruQu>mt_I9iSzpGRn5
mt_yCmYV9ruQu>mt_lAvS72LOUO
mt_ydtcIBwHB9>mt_VBl1T1sFCM
mt_ydtcIBwHB9>mt_YPSx5pbpVl
mt_yDZbQODIwp>mt_cpDpjJaE5u
mt_yDZbQODIwp>mt_JmMtZCifJB
mt_yDZbQODIwp>mt_-JnOhdei6F
mt_yDZbQODIwp>mt_mdZ3nBWChW
mt_yDZbQODIwp>mt_Wu-ftkzoiE
mt_yefw2CQT4x>mt_Qkl46lyris
mt_YFS7JFk64p>mt_i9rJbuFO3p
mt_yGv8doDAmp>mt_KJeEeTutJI
mt_yGv8doDAmp>mt_Qcp2d_kuta
mt_yhhprm7dZK>mt_R6YoRXkRxS
mt_yHQacItlhf>mt_sSQlLOnAow
mt_yHQacItlhf>mt_thsY1ZesaU
mt_yHQacItlhf>mt_v33BwiyRnd
mt_YHsUhi4Prc>mt_auJqTemMpI
mt_YHsUhi4Prc>mt_ChjMU2GDJa
mt_YHsUhi4Prc>mt_rDjtmDogJr
mt_yJmvUCCym7>mt_PgsHGYJMH-
mt_yK51ZnKA8m>mt_ATYLKt0je-
mt_yK51ZnKA8m>mt_FspV_imUGK
mt_yK51ZnKA8m>mt_WBdHkc2HTf
mt_yK51ZnKA8m>mt_xAf2bu9wYK
mt_yK51ZnKA8m>mt_XWSGuFW7It
mt_YKkCM63fSC>mt_frDIaXzWbx
mt_YKkCM63fSC>mt__KHQttMde3
mt_ylFTYS80d1>mt_tIi6L1n7kF
mt_ylruY6VhOf>mt_htAYR-iCFF
mt_ylruY6VhOf>mt_Pl-nsjYGZ3
mt_ylruY6VhOf>mt_YQkUdIHO8L
mt_ylXdiVRAYv>mt_dmNvjroCPT
mt_ylXdiVRAYv>mt_u5HkSxZECM
mt_ylXdiVRAYv>mt_xppl18avyY
mt_YNe6siFTFq>mt_4GiE83rJF_
mt_YNe6siFTFq>mt_fL1Xz8ostr
mt_YNe6siFTFq>mt_o8ciHks8t2
mt_YNe6siFTFq>mt_PJyCGJz5Hv
mt_YNe6siFTFq>mt_ZBMcX2oRor
mt_yNGrY9xJ8Y>mt_B1ATUEVNPz
mt_yNGrY9xJ8Y>mt_IR8kIjZn_V
mt_yNGrY9xJ8Y>mt_szw1Ln490b
mt_yNGrY9xJ8Y>mt_ZhUuT__i2H
mt_YNrrNE23dZ>mt_fpPLWFIRVo
mt_YNrrNE23dZ>mt_mKNmXqz_Oo
mt_yNWt3GQBNp>mt_A1Xfu5p5KT
mt_yNWt3GQBNp>mt_WNBHZ1d94L
mt_YQ64pzcLDl>mt_9yFAtUkoYr
mt_YQ64pzcLDl>mt_wq-1OJ_8s5
mt_yqAL6O5i_v>mt_dmNvjroCPT
mt_yqAL6O5i_v>mt_WcfaSfVT33
mt_YQkUdIHO8L>mt_1JFUNQDwAJ
mt_YQkUdIHO8L>mt_htAYR-iCFF
mt_YQkUdIHO8L>mt_Pl-nsjYGZ3
mt_YQkUdIHO8L>mt_SwaNNdm_Ks
mt_YQkUdIHO8L>mt_wf-SJhZ1kC
mt_yqZiX6vS7D>mt_2OtRUM_0zW
mt_yqZiX6vS7D>mt_8xVHooT4aI
mt_yqZiX6vS7D>mt_nTL-owFJTF
mt_yR1moI5kX1>mt_BI6oGIO-xM
mt__YRJ23GuIK>mt__h7hvT4tEb
mt_Yrjn8jAt1c>mt_Qxyikkkzam
mt_Yrjn8jAt1c>mt_z07UNAIsNc
mt_yrMniCJu_S>mt_sXRHr7tfS5
mt_yrMniCJu_S>mt_wwdRhPyz6s
mt_yrSdVrXrsF>mt_BnabTHkNIp
mt_yrSdVrXrsF>mt_DJh2JPwTf6
mt_ySnOkVIu22>mt_b6kZgqolEd
mt_ySnOkVIu22>mt_Jvg_r4yWaY
mt_YSyjTZfjvv>mt_BX4D8cCFtQ
mt_YSyjTZfjvv>mt_K8DJzqbksM
mt_YSyjTZfjvv>mt_Ruk2-lyGPZ
mt_Ytd8XC3eQr>mt_9Y5-GjF2B0
mt_yTWxkzzoOZ>mt_cChv2j_-Da
mt_yTWxkzzoOZ>mt_VAWV_l7J0D
mt_YUJ5pwalqL>mt_qUGMyMYn9m
mt_YvCgDM0Scg>mt_URTJbS3hhs
mt_Yw1_4Nfsql>mt_mpS-JK_p_m
mt_Yw27nweoTj>mt_-3udyo6VyB
mt_Yw27nweoTj>mt_GZuoYaDdWd
mt_yxL1v4LuqR>mt_oAg79ju344
mt_yxL1v4LuqR>mt_sQpIV0-qY7
mt_yXO7lQ9Yn7>mt_hBZwbst0ow
mt_yXO7lQ9Yn7>mt_vHzVa3SURC
mt_YXVQaufkKO>mt_N8CpN1EJrP
mt_YynJoQcm_M>mt_muxjw0fxxN
mt_YynJoQcm_M>mt_v3Vz_Pgjjv
mt_-YYnLLIZh5>mt_AB-TEMXSGJ
mt_-YYnLLIZh5>mt_fhqVdj4BYr
mt_-YYnLLIZh5>mt_iGSfQg3g5c
mt_-YYnLLIZh5>mt_-UAxilUtUt
mt_YzM5goBctT>mt_cFltwUQi-d
mt_YzM5goBctT>mt_nvdpxAJTBG
mt_z07UNAIsNc>mt_S2fP8rUwrl
mt_Z3G_97fnha>mt_18qkgxr_-T
mt_Z3G_97fnha>mt_IntmJBg4VQ
mt_Z3G_97fnha>mt_yBJyCfhtem
mt_Z5-fSCOBep>mt_nNYo5A-7Bl
mt_z5iwdZyeDr>mt_KwdjWEmMNo
mt_z5iwdZyeDr>mt_QhFEDyIwSO
mt_z7AJZapsJj>mt_jwElFY7Syd
mt_z7AJZapsJj>mt_NYA50DFcOO
mt_z7AJZapsJj>mt_vAP_A986IQ
mt_z98J_Zg2L3>mt_33zncDHC3N
mt_z98J_Zg2L3>mt_H8dEMH_wik
mt_z98J_Zg2L3>mt_rpug2tkYhb
mt_z98J_Zg2L3>mt_rqLMfiw61L
mt_z9jn9HogfE>mt_7OJjLOl0fz
mt_z9jn9HogfE>mt_aO018DkCun
mt_ZAJvTcroFO>mt_5r47Pvstyn
mt_ZanQuV90qi>mt_fL1Xz8ostr
mt_ZanQuV90qi>mt_SUOhjmRqv9
mt_zaXr5wcJD2>mt_mquPi2IP-J
mt_ZBMcX2oRor>mt_4A7FYmvVhA
mt_ZBMcX2oRor>mt_S0hzjAeLSK
mt_zBUcAPDRPM>mt_BhYJZUsErp
mt_zBUcAPDRPM>mt_EqXlZfB4jp
mt_zCUIJLdK_s>mt_AHAFw-atka
mt_zCUIJLdK_s>mt_cB7hV8sw7X
mt_zCUIJLdK_s>mt_tn1rY9GbEZ
mt_zCUIJLdK_s>mt_v5DyOEpbbr
mt_zd0YkB3xNj>mt_-P1kdZhHbL
mt_Zdv-b-iW5K>mt_gtTl3R5buH
mt_Zdv-b-iW5K>mt_iNdrM2-oJf
mt_ZFwPZaDJ0_>mt_Wa44s-f8Ws
mt_zfy1gOEewd>mt_nvdpxAJTBG
mt_zfy1gOEewd>mt_r0VXbfAmsH
mt_ZhKuYCbXz1>mt_5l7iGkf1Tp
mt_ZhKuYCbXz1>mt_ae-cHHFR76
mt_zHnOGwHIEz>mt_SwaNNdm_Ks
mt_zh_RyesCgZ>mt_mMMXD4v9Sh
mt_ZhUuT__i2H>mt_aFvsj35QzC
mt_ZhUuT__i2H>mt_XeMZdf2Y9W
mt_ZhvwM6LMBL>mt__KHQttMde3
mt_ZhvwM6LMBL>mt_YKkCM63fSC
mt_zir5yyAzUB>mt_yR1moI5kX1
mt_zIzJGkaj0Q>mt_h-z88yf9Pn
mt_zIzJGkaj0Q>mt_I9iSzpGRn5
mt_zIzJGkaj0Q>mt_q3vRl4dddK
mt_ZJC7JnnPCu>mt_IwEOCN6bL1
mt_ZJC7JnnPCu>mt_snlqRCiA1R
mt_ZJC7JnnPCu>mt_WsM4EmdOLe
mt_ZJu8s-Q1xa>mt_m6UaSmrQVG
mt_ZJu8s-Q1xa>mt_R6YoRXkRxS
mt_zkFbMLpu3U>mt_NtJYlJdUe9
mt_Zks8xyInSG>mt_d8al9JcajP
mt_Zks8xyInSG>mt_LlMl2PbaZe
mt_ZL9qVVnpwN>mt_4i-FKXDDXh
mt_ZLqYE7la4Z>mt_70qDTI14td
mt_zlSoIKPyId>mt_sSQlLOnAow
mt_zlSoIKPyId>mt_V-ldQp56bF
mt_zM5vu31jgl>mt_6Wx--Du8j3
mt_zM5vu31jgl>mt_fhqBH9scsU
mt_zM5vu31jgl>mt_lutxvMlkwS
mt_ZM7u9m-gS4>mt_2OSTHTWDpa
mt_ZM7u9m-gS4>mt_HJd-8EEC6N
mt_ZM7u9m-gS4>mt_kON8bYEHYl
mt_ZM9mhHsyYZ>mt_Vi4Vo5xs_g
mt_ZM9mhHsyYZ>mt_W17Kbwm0-u
mt_zMEvtigoM3>mt_20WfHhnL39
mt_zMEvtigoM3>mt_cqSf213hSa
mt_zMEvtigoM3>mt_glPPG-kTQY
mt_ZO2iP89cld>mt_wq-1OJ_8s5
mt_ZO2iP89cld>mt_YQ64pzcLDl
mt_ZOJ6EbdPOb>mt_3y7xKP9MjU
mt_ZOJ6EbdPOb>mt_6-j1NO2ZUH
mt_zOWwLxa77y>mt_8RmpkDxT9L
mt_zOWwLxa77y>mt_LpSuPgL31x
mt_zOWwLxa77y>mt_PZ909yPrEC
mt_ZpCcTU8j_o>mt_1z-gJBJFlM
mt_ZpCcTU8j_o>mt_DbI1kNg_0R
mt_ZpCcTU8j_o>mt_K6qtan847r
mt_zPDDJLAl-J>mt_C7FNeIDGc6
mt_zPDDJLAl-J>mt_tiPyEkm4cU
mt_zrCyqhngYm>mt__ab4knIaSL
mt_zrCyqhngYm>mt_SsS7GptD_o
mt_ZRoQVXf_aD>mt_dSeFrAWE4v
mt_ZRoQVXf_aD>mt_-JnOhdei6F
mt_ZRoQVXf_aD>mt_QtIAWOcoQT
mt_ZrsqGVG-Wt>mt_Jf8xcX4UTq
mt_zsYW61cn_q>mt_Sc_SorJhXW
mt_zsYW61cn_q>mt_v0K6GRi4ZL
mt_Zt30Gxi-qp>mt_t0g2SlP404
mt_Zt30Gxi-qp>mt_xSgAgg9Ej_
mt_zuKAX6lcYR>mt_dmNvjroCPT
mt_zuOGOGFAKb>mt_bfhng6mOuy
mt_zuOGOGFAKb>mt_sBcRdUfAzV
mt_ZWTk6eP1qF>mt_fhqVdj4BYr
mt_ZWTk6eP1qF>mt_v6CBCMuvz1
mt_ZWTk6eP1qF>mt_x5ZrQMAZ5v
mt_Z_Wu_77ybI>mt_b6kZgqolEd
mt_Zx1xZM-RbX>mt_e8CZ7E5qW7
mt_Zx1xZM-RbX>mt_T76hKqXf0z
mt_ZxdfRbwkKM>mt_FW9_8F52bw
mt_ZxdfRbwkKM>mt_QCWWmDMYZR
mt_zxST3MarI9>mt_aPBzD28_mT
mt_zxST3MarI9>mt_cChv2j_-Da
mt_Zy-CKUkq34>mt_LuwHnQItF_
mt_Zy-CKUkq34>mt_M_xcaRcvSo
"""
}
