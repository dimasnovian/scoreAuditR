"""Run with Python and kagglehub installed; retrieves the studied version."""
from pathlib import Path
import kagglehub
dataset = "jainaru/world-happiness-report-2024-yearly-updated/versions/1"
path = kagglehub.dataset_download(dataset)
print("Studied dataset version:", dataset)
print("Path to dataset files:", path)
print("Annual CSV files:")
for file in Path(path).glob("*.csv"):
    print(file)
