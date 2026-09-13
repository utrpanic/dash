package dev.utrpanic.dash.domain.model

object BusRouteNaturalComparator : Comparator<BusRoute> {
    private val tokenPattern = Regex("\\d+|\\D+")

    override fun compare(first: BusRoute, second: BusRoute): Int {
        val firstTokens = tokenPattern.findAll(first.number).map { it.value }.toList()
        val secondTokens = tokenPattern.findAll(second.number).map { it.value }.toList()
        for (index in 0 until minOf(firstTokens.size, secondTokens.size)) {
            val firstToken = firstTokens[index]
            val secondToken = secondTokens[index]
            val comparison = if (firstToken.all(Char::isDigit) && secondToken.all(Char::isDigit)) {
                firstToken.toLong().compareTo(secondToken.toLong())
            } else {
                firstToken.compareTo(secondToken, ignoreCase = true)
            }
            if (comparison != 0) return comparison
        }
        return firstTokens.size.compareTo(secondTokens.size)
            .takeIf { it != 0 }
            ?: first.number.compareTo(second.number)
    }
}
