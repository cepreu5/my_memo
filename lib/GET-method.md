Ето как изглежда реализацията на втория метод (Web Scraping / Парсване на Open Graph тагове) с обикновена GET заявка.
Този метод е много удобен, защото **не изисква App ID, App Secret или каквито и да е ключове**. Основният трик тук е използването на правилен User-Agent хедър. Ако изпратите базова заявка от Kotlin, Facebook ще разпознае, че сте скрипт, и ще върне страница за вход (login) или страница за неподдържан браузър, в които липсват желаните мета тагове.
За да заобиколим това, в примера **имитираме бота на WhatsApp**. Facebook умишлено му позволява достъп, за да може WhatsApp да генерира картинки (link previews) при споделяне на линкове в чата.
### Kotlin код за Web Scraping на Open Graph
```kotlin
import java.net.HttpURLConnection
import java.net.URL

fun main() {
    // ВАРИАНТ 1: Стандартен линк към Facebook видео
    val standardVideoUrl = "https://www.facebook.com/facebook/videos/10153231379946729/"
    
    // ВАРИАНТ 2: Линк към Facebook Reel (с проследяващи параметри)
    val rawReelUrl = "https://www.facebook.com/reel/123456789012345/?mibextid=Nif5oz"
    
    // Както и при oEmbed, почистваме Reel линка от параметрите след въпросителния знак
    val cleanReelUrl = cleanFacebookUrl(rawReelUrl)

    println("--- Тест 1: Стандартно видео ---")
    val standardThumb = getThumbnailFromOpenGraph(standardVideoUrl)
    println("Миниатюра: $standardThumb\n")

    println("--- Тест 2: Facebook Reel ---")
    val reelThumb = getThumbnailFromOpenGraph(cleanReelUrl)
    println("Миниатюра: $reelThumb")
}

/**
 * Премахва query параметрите от URL адреса.
 */
fun cleanFacebookUrl(url: String): String {
    return url.substringBefore("?")
}

/**
 * Изпраща GET заявка и търси мета тага og:image в HTML кода.
 */
fun getThumbnailFromOpenGraph(videoUrl: String): String? {
    return try {
        val connection = URL(videoUrl).openConnection() as HttpURLConnection
        connection.requestMethod = "GET"
        connection.connectTimeout = 5000
        connection.readTimeout = 5000
        
        // КРИТИЧНА СТЪПКА: Задаваме User-Agent на WhatsApp или Googlebot
        // Без този хедър Facebook няма да върне Open Graph таговете
        connection.setRequestProperty("User-Agent", "WhatsApp/2.21.24.22 A")
        
        if (connection.responseCode == HttpURLConnection.HTTP_OK) {
            // Четем целия HTML отговор
            val html = connection.inputStream.bufferedReader().use { it.readText() }
            
            // Използваме Regex, за да намерим стойността на content атрибута в тага og:image
            // Търсим структура като: property="og:image" content="https://..."
            val regex = """property="og:image"\s+content="([^"]+)"""".toRegex()
            val matchResult = regex.find(html)
            
            var imageUrl = matchResult?.groups?.get(1)?.value
            
            // В HTML кода амперсандите (&) често са ескейпнати като &amp;
            // Възстановяваме ги, за да бъде линкът валиден
            imageUrl = imageUrl?.replace("&amp;", "&")
            
            imageUrl
        } else {
            println("Грешка от сървъра: Код ${connection.responseCode}")
            null
        }
    } catch (e: Exception) {
        println("Възникна изключение: ${e.message}")
        null
    }
}

```
### Защо този метод е полезен и какви са рисковете?
 * **Предимства:** Не ви трябва Facebook App (Developer акаунт). Работи незабавно. Извлича изображението с най-високо качество, което е зададено за споделяне в социалните мрежи.
 * **Ограничения (Регекс срещу HTML Парсър):** В базовия пример използвам Regex (Регулярни изрази), за да не добавям външни библиотеки. В професионална среда е препоръчително да използвате библиотека за парсване на HTML (като **Jsoup**). Facebook понякога разменя местата на атрибутите (напр. content="..." property="og:image"), което би счупило простия регекс, но Jsoup ще се справи безпроблемно.
 * **Ограничения (Блокиране):** Въпреки че мамим системата с User-Agent, ако правите хиляди заявки от един и същ IP адрес, Facebook може временно да блокира достъпа ви или да започне да връща CAPTCHA проверки. За леко или умерено ползване методът работи отлично.
