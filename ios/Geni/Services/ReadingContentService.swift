import Foundation

enum ReadingContentService {
    static func textForToday(profile: ChildProfile, date: String) -> ReadingText {
        let texts = allTexts.filter { $0.ageGroup == profile.ageGroup }
        guard !texts.isEmpty else { return allTexts[0] }
        let hash = abs(date.hashValue)
        return texts[hash % texts.count]
    }

    static func parseWords(from text: String) -> [ReadingWord] {
        let components = text.components(separatedBy: " ").filter { !$0.isEmpty }
        var words: [ReadingWord] = []
        var charIndex = 0
        for (i, word) in components.enumerated() {
            let start = charIndex
            let end = charIndex + word.count
            words.append(ReadingWord(id: i, text: word, startIndex: start, endIndex: end))
            charIndex = end + 1
        }
        return words
    }

    static func secondsPerWord(totalWords: Int, targetSeconds: Int) -> Double {
        guard totalWords > 0 else { return 1.0 }
        return Double(targetSeconds) / Double(totalWords)
    }

    private static let allTexts: [ReadingText] = youngTextsEN + middleTextsEN + olderTextsEN

    private static let youngTextsEN: [ReadingText] = [
        ReadingText(
            id: "y1", titleEN: "The Little Cat", titleNO: "Den lille katten",
            contentEN: "The sun is up. A small cat sits on a red mat. The cat is soft and warm. It has big green eyes. The cat likes to nap in the sun. It purrs and purrs. A yellow bird sings in a tall tree. The cat looks up at the bird. The bird flies far away. The cat yawns and goes back to sleep. What a lazy day!",
            contentNO: "Solen er oppe. En liten katt sitter p\u{00E5} en r\u{00F8}d matte. Katten er myk og varm. Den har store gr\u{00F8}nne \u{00F8}yne. Katten liker \u{00E5} sove i solen. Den spinner og spinner. En gul fugl synger i et h\u{00F8}yt tre. Katten ser opp p\u{00E5} fuglen. Fuglen flyr langt bort. Katten gjesper og sover videre. For en lat dag!",
            ageGroup: .young
        ),
        ReadingText(
            id: "y2", titleEN: "My Dog Sam", titleNO: "Hunden min Sam",
            contentEN: "I have a dog. His name is Sam. Sam is brown and big. He likes to run in the park. He can catch a ball! Sam wags his tail when he is happy. He loves to play with me. We run and jump all day. Then we sit and rest. Sam puts his head on my lap. He is my best friend.",
            contentNO: "Jeg har en hund. Han heter Sam. Sam er brun og stor. Han liker \u{00E5} l\u{00F8}pe i parken. Han kan fange en ball! Sam logrer med halen n\u{00E5}r han er glad. Han elsker \u{00E5} leke med meg. Vi l\u{00F8}per og hopper hele dagen. S\u{00E5} sitter vi og hviler. Sam legger hodet sitt i fanget mitt. Han er min beste venn.",
            ageGroup: .young
        ),
        ReadingText(
            id: "y3", titleEN: "The Rain", titleNO: "Regnet",
            contentEN: "Drop, drop, drop! It is raining today. I look out the window. The sky is gray. I see big puddles on the ground. I put on my yellow coat. I put on my red boots. I go out to play! I jump in the puddles. Splash, splash! The rain feels cool on my face. I love rainy days. When I come home, I drink warm milk.",
            contentNO: "Drypp, drypp, drypp! Det regner i dag. Jeg ser ut av vinduet. Himmelen er gr\u{00E5}. Jeg ser store pytter p\u{00E5} bakken. Jeg tar p\u{00E5} meg den gule jakken. Jeg tar p\u{00E5} meg de r\u{00F8}de st\u{00F8}vlene. Jeg g\u{00E5}r ut for \u{00E5} leke! Jeg hopper i pyttene. Plask, plask! Regnet f\u{00F8}les kaldt p\u{00E5} ansiktet mitt. Jeg elsker regnv\u{00E6}rsdager.",
            ageGroup: .young
        ),
        ReadingText(
            id: "y4", titleEN: "The Big Tree", titleNO: "Det store treet",
            contentEN: "In my garden there is a big tree. It has many green leaves. In spring, pink flowers grow on it. Birds make nests in the tree. I can hear them sing every morning. I like to sit under the tree. It gives me cool shade when it is hot. My dad says the tree is very old. I want to climb it one day!",
            contentNO: "I hagen min st\u{00E5}r et stort tre. Det har mange gr\u{00F8}nne blader. Om v\u{00E5}ren vokser rosa blomster p\u{00E5} det. Fugler lager reir i treet. Jeg kan h\u{00F8}re dem synge hver morgen. Jeg liker \u{00E5} sitte under treet. Det gir meg kjølig skygge n\u{00E5}r det er varmt. Pappa sier treet er veldig gammelt. Jeg vil klatre i det en dag!",
            ageGroup: .young
        ),
    ]

    private static let middleTextsEN: [ReadingText] = [
        ReadingText(
            id: "m1", titleEN: "The Secret Garden", titleNO: "Den hemmelige hagen",
            contentEN: "Last summer, my family moved to a new house. Behind the house, there was a tall wooden fence covered in green vines. One day, I found a small rusty key under a rock near the gate. I tried the key in the old lock, and it turned! The gate creaked open slowly. Behind it was the most beautiful garden I had ever seen. There were flowers of every color, red roses, purple violets, and bright yellow sunflowers that were taller than me. A small fountain bubbled in the middle, and butterflies danced from flower to flower. I decided this would be my secret place. Every afternoon after school, I would come here to read, draw, and dream. The garden became my favorite spot in the whole world.",
            contentNO: "Forrige sommer flyttet familien min til et nytt hus. Bak huset var det et h\u{00F8}yt tregjerde dekket med gr\u{00F8}nne slyngplanter. En dag fant jeg en liten rusten n\u{00F8}kkel under en stein ved porten. Jeg pr\u{00F8}vde n\u{00F8}kkelen i den gamle l\u{00E5}sen, og den snudde! Porten knirket sakte opp. Bak den var den vakreste hagen jeg noensinne hadde sett. Det var blomster i alle farger, r\u{00F8}de roser, lilla fioler og lyse gule solsikker som var h\u{00F8}yere enn meg. En liten fontene boblet i midten, og sommerfugler danset fra blomst til blomst. Jeg bestemte meg for at dette skulle v\u{00E6}re mitt hemmelige sted. Hver ettermiddag etter skolen kom jeg hit for \u{00E5} lese, tegne og dr\u{00F8}mme. Hagen ble mitt favorittsted i hele verden.",
            ageGroup: .middle
        ),
        ReadingText(
            id: "m2", titleEN: "The Brave Little Fox", titleNO: "Den modige lille reven",
            contentEN: "Deep in the forest, a young fox named Finn lived with his mother. Finn was smaller than the other foxes, but he was very clever. One cold winter morning, Finn woke up to find that a heavy snowstorm had blocked the entrance to their den. His mother was still sleeping. Finn knew he had to find another way out. He dug carefully through the soft snow on the side of the hill. After a long time, he broke through to the outside. The world was white and sparkling. Finn found berries under the snow and brought them home for breakfast. His mother was so proud of him. From that day on, everyone in the forest called him Finn the Brave.",
            contentNO: "Dypt inne i skogen bodde en ung rev som het Finn sammen med moren sin. Finn var mindre enn de andre revene, men han var veldig smart. En kald vintermorgon v\u{00E5}knet Finn og oppdaget at en kraftig sn\u{00F8}storm hadde blokkert inngangen til hiet deres. Moren hans sov fortsatt. Finn visste at han m\u{00E5}tte finne en annen vei ut. Han gravde forsiktig gjennom den myke sn\u{00F8}en p\u{00E5} siden av h\u{00F8}yden. Etter lang tid brøt han gjennom til utsiden. Verden var hvit og glitrende. Finn fant b\u{00E6}r under sn\u{00F8}en og tok dem med hjem til frokost. Moren hans var s\u{00E5} stolt av ham. Fra den dagen kalte alle i skogen ham Finn den Modige.",
            ageGroup: .middle
        ),
        ReadingText(
            id: "m3", titleEN: "Amazing Octopuses", titleNO: "Fantastiske blekkspruter",
            contentEN: "Did you know that octopuses are some of the smartest animals in the ocean? They have eight long arms and a soft body with no bones at all. This means they can squeeze through tiny spaces, even through a hole as small as a coin! Octopuses can also change their color in less than a second. They do this to hide from danger or to talk to other octopuses. Some octopuses even pick up coconut shells and carry them around to use as shelters. Scientists have watched octopuses solve puzzles and open jars to get food inside. They are truly amazing creatures that still surprise us with new discoveries every year.",
            contentNO: "Visste du at blekkspruter er noen av de smarteste dyrene i havet? De har \u{00E5}tte lange armer og en myk kropp uten noen bein i det hele tatt. Det betyr at de kan presse seg gjennom sm\u{00E5} \u{00E5}pninger, til og med gjennom et hull s\u{00E5} lite som en mynt! Blekkspruter kan ogs\u{00E5} endre farge p\u{00E5} under ett sekund. De gj\u{00F8}r dette for \u{00E5} gjemme seg for fare eller for \u{00E5} snakke med andre blekkspruter. Noen blekkspruter plukker til og med opp kokosskall og b\u{00E6}rer dem rundt for \u{00E5} bruke som ly. Forskere har sett blekkspruter l\u{00F8}se puslespill og \u{00E5}pne glass for \u{00E5} f\u{00E5} tak i mat. De er virkelig fantastiske skapninger.",
            ageGroup: .middle
        ),
        ReadingText(
            id: "m4", titleEN: "The Lost Kite", titleNO: "Den tapte dragen",
            contentEN: "On a windy Saturday, Emma took her new red kite to the hill near her house. The wind was perfect, and the kite flew high into the sky. Emma laughed as it danced above the clouds. But then a strong gust of wind pulled the string right out of her hands! The kite sailed away over the trees. Emma ran after it as fast as she could. She followed it through the meadow, past the old barn, and all the way to the river. There, caught in a willow tree, was her red kite. A friendly boy named Leo helped her get it down. They spent the rest of the afternoon flying the kite together and became good friends.",
            contentNO: "En vindfull l\u{00F8}rdag tok Emma med seg den nye r\u{00F8}de dragen sin til h\u{00F8}yden n\u{00E6}r huset hennes. Vinden var perfekt, og dragen fl\u{00F8}y h\u{00F8}yt opp p\u{00E5} himmelen. Emma lo mens den danset over skyene. Men s\u{00E5} dro et kraftig vindkast snoren rett ut av hendene hennes! Dragen seilte bort over tr\u{00E6}rne. Emma l\u{00F8}p etter den s\u{00E5} fort hun kunne. Hun fulgte den gjennom engen, forbi den gamle l\u{00E5}ven og helt ned til elven. Der, fanget i et piletre, var den r\u{00F8}de dragen hennes. En hyggelig gutt som het Leo hjalp henne med \u{00E5} f\u{00E5} den ned. De tilbrakte resten av ettermiddagen med \u{00E5} fly dragen sammen og ble gode venner.",
            ageGroup: .middle
        ),
    ]

    private static let olderTextsEN: [ReadingText] = [
        ReadingText(
            id: "o1", titleEN: "The Mystery of the Lighthouse", titleNO: "Mysteriet p\u{00E5} fyret",
            contentEN: "The old lighthouse on Gull Island had been abandoned for twenty years. Nobody went there anymore, not since the last keeper had left without a word. But every night, the people in the fishing village across the bay could still see a faint light flickering in the tower window. Some said it was just the moonlight reflecting off the glass. Others whispered that it was the ghost of Captain Morgan, who had disappeared during a terrible storm long ago. Twelve-year-old Maya did not believe in ghosts. She was curious and brave, and she wanted to find out the truth. One foggy morning, she borrowed her uncle\u{2019}s rowboat and paddled across the bay to the island. The lighthouse door was unlocked. Inside, the spiral staircase was dusty but solid. She climbed all the way to the top. There, in the lamp room, she found something unexpected: a family of barn owls had made their nest right next to the old mirror. When the moonlight hit the mirror, it reflected through the glass and created the mysterious glow. Maya smiled. The mystery was solved, and she had made some feathery new friends.",
            contentNO: "Det gamle fyret p\u{00E5} M\u{00E5}ke\u{00F8}ya hadde st\u{00E5}tt forlatt i tjue \u{00E5}r. Ingen dro dit lenger, ikke siden den siste fyrpasseren hadde dratt uten et ord. Men hver natt kunne folkene i fiskerlandsbyen p\u{00E5} den andre siden av bukten fortsatt se et svakt lys som flimret i t\u{00E5}rnvinduet. Noen sa det bare var m\u{00E5}nelyset som reflekterte i glasset. Andre hvisket at det var sp\u{00F8}kelset til Kaptein Morgan, som hadde forsvunnet under en fryktelig storm for lenge siden. Tolv \u{00E5}r gamle Maya trodde ikke p\u{00E5} sp\u{00F8}kelser. Hun var nysgjerrig og modig, og hun ville finne ut sannheten. En t\u{00E5}kete morgen l\u{00E5}nte hun onkelens rob\u{00E5}t og rodde over bukten til \u{00F8}ya. Fyrd\u{00F8}ren var ul\u{00E5}st. Inni var vindeltrappen st\u{00F8}vete, men solid. Hun klatret helt opp til toppen. Der, i lamprommet, fant hun noe uventet: en familie med t\u{00E5}rnugler hadde laget reir rett ved siden av det gamle speilet. N\u{00E5}r m\u{00E5}nelyset traff speilet, reflekterte det gjennom glasset og skapte den mystiske gløden. Maya smilte. Mysteriet var l\u{00F8}st, og hun hadde f\u{00E5}tt noen fjærlete nye venner.",
            ageGroup: .older
        ),
        ReadingText(
            id: "o2", titleEN: "Life on Mars?", titleNO: "Liv p\u{00E5} Mars?",
            contentEN: "For hundreds of years, people have looked up at the red dot in the night sky and wondered: is there life on Mars? Today, scientists are closer than ever to finding out. Mars is the fourth planet from the Sun and the most similar to Earth in our solar system. It has seasons, polar ice caps, and even dust storms that can cover the entire planet. Several robots, called rovers, have been sent to explore the surface of Mars. They have found dried-up riverbeds, which means water once flowed there. Where there is water, there might be life, even if it is just tiny bacteria. Scientists are also planning to send humans to Mars within the next twenty years. The journey would take about seven months. The astronauts would need to bring everything with them: food, water, air, and building materials. Some people dream of one day building cities on Mars. It sounds like science fiction, but many of the technologies we need are already being developed right now. Perhaps one day, you could be among the first people to walk on another planet.",
            contentNO: "I hundrevis av \u{00E5}r har folk sett opp p\u{00E5} den r\u{00F8}de prikken p\u{00E5} nattehimmelen og lurt: finnes det liv p\u{00E5} Mars? I dag er forskere n\u{00E6}rmere enn noensinne \u{00E5} finne ut. Mars er den fjerde planeten fra solen og den mest like Jorden i solsystemet v\u{00E5}rt. Den har \u{00E5}rstider, polare iskapper og til og med sandstormer som kan dekke hele planeten. Flere roboter, kalt rovere, har blitt sendt for \u{00E5} utforske overflaten p\u{00E5} Mars. De har funnet utt\u{00F8}rkede elveleier, noe som betyr at vann en gang fløt der. Der det er vann, kan det v\u{00E6}re liv, selv om det bare er sm\u{00E5} bakterier. Forskere planlegger ogs\u{00E5} \u{00E5} sende mennesker til Mars i l\u{00F8}pet av de neste tjue \u{00E5}rene. Reisen ville ta omtrent syv m\u{00E5}neder. Astronautene m\u{00E5} ta med seg alt: mat, vann, luft og byggematerialer. Noen dr\u{00F8}mmer om \u{00E5} en dag bygge byer p\u{00E5} Mars. Det h\u{00F8}res ut som science fiction, men mange av teknologiene vi trenger, blir allerede utviklet n\u{00E5}. Kanskje en dag kan du v\u{00E6}re blant de f\u{00F8}rste som g\u{00E5}r p\u{00E5} en annen planet.",
            ageGroup: .older
        ),
        ReadingText(
            id: "o3", titleEN: "The Clockmaker\u{2019}s Apprentice", titleNO: "Klokkemakerens l\u{00E6}rling",
            contentEN: "In a small town tucked between two mountains, there lived an old clockmaker named Mr. Stein. His shop was filled with hundreds of clocks of every shape and size. Grandfather clocks, cuckoo clocks, pocket watches, and tiny music boxes that played beautiful melodies when you opened them. Every clock in Mr. Stein\u{2019}s shop told perfect time. When ten-year-old Aiden walked past the shop one afternoon, he stopped and pressed his nose against the glass. The window was full of spinning gears, swinging pendulums, and ticking hands. Mr. Stein saw the boy and waved him inside. That was the beginning of an unexpected friendship. Every day after school, Aiden would visit the shop. Mr. Stein taught him how gears work together, how springs store energy, and how a tiny balance wheel keeps time with incredible accuracy. Aiden learned to take apart a clock and put it back together with steady hands and patience. By the end of the year, Aiden had built his very first clock from scratch. It was not perfect, but it kept time, and Mr. Stein said that was the most important thing.",
            contentNO: "I en liten by mellom to fjell bodde det en gammel klokkemaker som het herr Stein. Butikken hans var fylt med hundrevis av klokker i alle former og st\u{00F8}rrelser. Gulvklokker, gj\u{00F8}kklokker, lommeur og sm\u{00E5} spilledoser som spilte vakre melodier n\u{00E5}r du \u{00E5}pnet dem. Hver klokke i herr Steins butikk viste perfekt tid. Da ti \u{00E5}r gamle Aiden gikk forbi butikken en ettermiddag, stoppet han og presset nesen mot glasset. Vinduet var fullt av snurrende tannhjul, svingende pendler og tikkende visere. Herr Stein s\u{00E5} gutten og vinket ham inn. Det var begynnelsen p\u{00E5} et uventet vennskap. Hver dag etter skolen bes\u{00F8}kte Aiden butikken. Herr Stein l\u{00E6}rte ham hvordan tannhjul fungerer sammen, hvordan fj\u{00E6}rer lagrer energi, og hvordan et lite balansehjul holder tiden med utrolig n\u{00F8}yaktighet. Aiden l\u{00E6}rte \u{00E5} ta fra hverandre en klokke og sette den sammen igjen med st\u{00F8}dige hender og t\u{00E5}lmodighet. Ved slutten av \u{00E5}ret hadde Aiden bygget sin aller f\u{00F8}rste klokke fra bunnen av. Den var ikke perfekt, men den holdt tiden, og herr Stein sa at det var det viktigste.",
            ageGroup: .older
        ),
        ReadingText(
            id: "o4", titleEN: "The Deep Ocean", titleNO: "Det dype havet",
            contentEN: "The ocean covers more than seventy percent of our planet, yet we have explored less than five percent of it. The deepest point on Earth is the Mariana Trench in the Pacific Ocean. It goes down nearly eleven kilometers, deeper than Mount Everest is tall! At the bottom, the pressure is so great that it would crush most submarines. The water is near freezing and completely dark because sunlight cannot reach that far. Yet even in this extreme environment, life exists. Scientists have discovered strange creatures that glow in the dark, fish with enormous eyes that can see in almost no light, and tiny organisms that survive on chemicals from underwater volcanoes instead of sunlight. Some of these creatures look like they belong in a science fiction movie. Every time a deep-sea expedition goes down, it finds species that have never been seen before. The ocean floor is truly the last frontier on Earth, and exploring it is one of the greatest adventures of our time.",
            contentNO: "Havet dekker mer enn sytti prosent av planeten v\u{00E5}r, men vi har utforsket mindre enn fem prosent av det. Det dypeste punktet p\u{00E5} Jorden er Marianergropen i Stillehavet. Den g\u{00E5}r nesten elleve kilometer ned, dypere enn Mount Everest er h\u{00F8}y! P\u{00E5} bunnen er trykket s\u{00E5} stort at det ville knuse de fleste ub\u{00E5}ter. Vannet er nesten frysende og helt m\u{00F8}rkt fordi sollys ikke n\u{00E5}r s\u{00E5} langt. Likevel finnes det liv selv i dette ekstreme milj\u{00F8}et. Forskere har oppdaget merkelige skapninger som lyser i m\u{00F8}rket, fisker med enorme \u{00F8}yne som kan se i nesten ikke noe lys, og sm\u{00E5} organismer som overlever p\u{00E5} kjemikalier fra undervannsvulkaner i stedet for sollys. Noen av disse skapningene ser ut som de h\u{00F8}rer hjemme i en science fiction-film. Hver gang en dyphavsekspedisjon g\u{00E5}r ned, finner den arter som aldri har blitt sett f\u{00F8}r. Havbunnen er virkelig den siste grensen p\u{00E5} Jorden.",
            ageGroup: .older
        ),
    ]
}
