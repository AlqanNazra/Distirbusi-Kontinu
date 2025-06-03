# 🔍 Anomaly Detection dengan Regresi Linier di Julia

Aplikasi ini melakukan deteksi anomali menggunakan model Regresi Linier pada
data jaringan yang telah diproses menggunakan one-hot encoding.
Proyek ini dibangun menggunakan bahasa pemrograman Julia, 
dengan bantuan paket-paket seperti `DataFrames`, `CSV`, `GLM`, dan `MLJ`.

---

## 📂 Struktur Proyek
├── data_latih.csv # Data latih (dengan label 'normal' dan 'anomaly')
├── data_uji.csv # Data uji (untuk validasi model)
├── Regresi_Linier.jl # Skrip utama Julia
└── README.md # Dokumentasi proyek

## 🧰 Dependencies
Pastikan Anda sudah menginstall Julia dan paket-paket berikut:

julia
using Pkg
Pkg.add("CSV")
Pkg.add("DataFrames")
Pkg.add("CategoricalArrays")
Pkg.add("Statistics")
Pkg.add("GLM")
Pkg.add("MLJBase")
Pkg.add("MLJModels")
using Plots, StatsBase

## Cara Menjalankan
1. Buatkan data_latih.csv dan data_uji.cv didirektori yang sama dengan file Regresi_Linier.jl.
2. Jalankan file .jl menggunakan terminal atau VScode

## Fitur
Preprocessing: 
a. Konversi fitur kategorikal ke tipe kategori (CategoricalArrays)
b. Konversi label normal/anomaly ke 0/1
c. One-hot encoding untuk fitur kategorikal
Modeling
a. Regresi linier dengan semua fitur sebagai prediktor
b. Penentuan ambang batas (threshold) dari prediksi minimal pada data anomaly
Evaluasi
a. Prediksi terhadap data uji
b. Klasifikasi berdasarkan threshold
c. Perhitungan akurasi


Tim yang mengerjakan
Alqan Nazra = 2315111068


