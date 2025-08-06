# YouTube Trending Global: What Drives a Video to Trend?

**Business Problem:**  
What features and behaviors drive videos to trend across different countries and categories on YouTube?

---

## 📈 Approach

- **Exploratory Data Analysis (EDA)** using Python (pandas, matplotlib, seaborn)
- **Engagement metric analysis:** views, likes, comments
- **Breakdown by category and country**
- **Clear code and explanations in each step**
- **All visualizations and analysis are fully reproducible with the provided notebook**

---

## 🔎 Dataset

- **Source:** [YouTube Trending Videos Global on Kaggle](https://www.kaggle.com/datasets/canerkonuk/youtube-trending-videos-global)
- **Important Note:**  
  The dataset is updated daily on Kaggle.  
  **This analysis uses the version downloaded on _06-AUG-25_ and results may differ if the dataset is refreshed in the future.**

---

## 📂 Repository Structure

- [`Notebooks/YouTube Trending Global.ipynb`](./Notebooks/YouTube%20Trending%20Global.ipynb)  
  _The full analysis notebook, with code, markdown, and output._
- [`Charts/`](./Charts)  
  _All generated figures and plots for easy review._

---

## 🚀 Key Insights

- **Pets & Animals** and **How-to & Style** categories generate the highest average views per trending video—outperforming even Music and Entertainment.
- **Most trending videos are under 20 minutes** in length, with a strong right-skew in the distribution.
- **Views and likes are highly correlated** (_r_ = 0.89), but comments show a weaker correlation with both.
- By country, regions like **Bangladesh and Malaysia** have the highest average view counts per trending video in the current data snapshot.

---

## 📊 How to Reproduce

1. Download the latest dataset from Kaggle, or use the version as of _06-AUG-25_ for identical results.
2. Open the provided notebook in [`Notebooks/`](./Notebooks) and run all cells.
3. All generated charts are available in [`Charts/`](./Charts).

---

## 🧹 Cleaning Notes

- Focused on columns with the most complete data: views, likes, comments, category, and country.
- Converted video duration from ISO 8601 format to seconds using custom Python logic.
- Only minimal cleaning was necessary due to high dataset quality.

---

## 📝 Next Steps

- Explore trends over time as new data is released.
- Use NLP to analyze video descriptions or tags for deeper content insights.
- Build a predictive model for “likelihood to trend” using additional features.

---

## 📚 References

- [YouTube Trending Videos Global on Kaggle](https://www.kaggle.com/datasets/canerkonuk/youtube-trending-videos-global)

---

_This case study is part of a growing [Data Analytics Case Studies Portfolio](../..) by Junelle James Ford._
