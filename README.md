# GA4 E-Commerce Funnel Analysis

Where do users drop off on the way to a purchase, and which step should be fixed first?

## Data

Google's public GA4 sample dataset for the Google Merchandise Store:
`bigquery-public-data.ga4_obfuscated_sample_ecommerce`

## Method

1. **Event level:** pull each event with its session ID, date, revenue, page path, device and traffic source (nested `event_params` fields extracted with `UNNEST`).
2. **Session level:** mark each funnel step as 1 or 0 per session (binary funnel logic), so a session counts once per step.
3. **Output:** aggregate by date, device, language, traffic source and landing page, with session and user conversion rates.

Funnel steps: session start → product view → add to cart → begin checkout → shipping info → payment info → purchase

The query is in [`ga4-funnel.sql`](ga4-funnel.sql). The result feeds a 10-sheet Tableau Public dashboard with KPI cards and filters.

**Run it yourself:** the dataset is public, so the query runs as-is in the [BigQuery console](https://console.cloud.google.com/bigquery) with any Google account (free sandbox).

## Key findings

- **78%** of sessions drop off between session start and product view.
- **38%** drop off between shipping info and payment info.

## Links

- [Tableau dashboard](https://public.tableau.com/app/profile/g.l.g.m.dere/viz/FinalEcommersFunnelProje/Dashboard1)
- [Loom walkthrough](https://www.loom.com/share/8c28fed5207d4111af8e78ffde3f0140)

## Tools

BigQuery (SQL) · Tableau Public
