# YouTube Trending Global: What Drives a Video to Trend?

**Business Problem:**  
What features and behaviors drive videos to trend across different countries and categories on YouTube?

**Approach:**
- Exploratory Data Analysis (EDA) using Python (pandas, matplotlib, seaborn)
- Engagement metric analysis (views, likes, comments)
- Breakdown by category and country
- Clear markdown and code in each step

**Key Insights:**
- Pets & Animals and How-to & Style have the highest average views per trending video
- Most trending videos are under 20 minutes
- Views and likes are highly correlated (r=0.89), but comments are less so (r=0.25)

**How to Reproduce:**
- Open `notebook.ipynb` in this folder
- All code and charts are saved in the `charts/` directory

**Dataset Source:**  
[YouTube Trending Videos Global on Kaggle](https://www.kaggle.com/datasets/canerkonuk/youtube-trending-videos-global)

**Cleaning Notes:**  
- Focused analysis on most complete fields (views, likes, comments, category, country)
- Converted ISO 8601 durations to seconds

**Next Steps:**  
Future work could include NLP on descriptions/tags, predictive modeling, or time-series trend analysis.
