# Inside Steam - Analysis Plan

## Main Analytical Question

How do game characteristics, pricing and market positioning relate to player reach, engagement and satisfaction on Steam?

## Analytical Dimensions

### Market Positioning
- Price
- Free-to-play vs paid
- Genres
- Tags
- Publishers
- Developers
- Release period

### Market Reach
- Estimated owners
- Review volume
- Recommendations
- Peak CCU

### Player Engagement
- Average lifetime playtime
- Median lifetime playtime
- Peak CCU

### Player Reception
- Overall positive review percentage
- Recent positive review percentage
- Positive and negative review counts
- Metacritic score (secondary analysis)

## Core KPIs
- Number of games
- Median price
- Free-to-play share
- Estimated reach
- Overall positive review percentage
- Review volume

## Subset Metrics
- Peak CCU
- Lifetime playtime
- Recent review positivity
- Metacritic score

## Main Analytical Questions
1. How has the Steam catalogue evolved over time?
2. How is the market distributed across genres, publishers and pricing models?
3. How concentrated is player reach across the Steam catalogue?
4. How does pricing relate to estimated reach and player reception?
5. Are the most widely owned games also the most positively reviewed?
6. Which genres or market segments generate particularly strong player engagement?
7. Which games outperform their peers in reach, engagement or reception?
8. Where critic reception is available, how closely does it align with player reception?

## Known Data Considerations
- `estimated_owners` is stored as ranges rather than exact counts.
- Review variables use `-1` as a sentinel value for unavailable data.
- `user_score` has insufficient coverage for meaningful analysis.
- Metacritic, playtime and recent engagement metrics will require subset analysis.
- Extreme game prices were verified as possible real observations rather than automatically treated as data errors.
