# Impor paket yang diperlukan
try
    using CSV
    using DataFrames
    using CategoricalArrays
    using Statistics
    using StatsBase
    using Plots
    using Distributions
catch e
    println("Error: Salah satu paket tidak ditemukan. Silakan instal paket yang diperlukan.")
    println("Jalankan: import Pkg; Pkg.add(\"NamaPaket\") untuk paket yang hilang.")
    println("Paket yang diperlukan: CSV, DataFrames, CategoricalArrays, Statistics, StatsBase, Plots, Distributions")
    rethrow(e)
end

# Set backend plotting ke GR
gr()

# ==================== BACA DAN PREPROSES DATA LATIH ====================

# Tentukan path file
file_path = "data_train.csv"

# Periksa apakah file ada
if !isfile(file_path)
    error("File $file_path tidak ditemukan di direktori $(pwd()). Pastikan file ada di direktori yang benar.")
end

# Inisialisasi data_latih sebagai variabel global
global data_latih = nothing
try
    global data_latih = CSV.read(file_path, DataFrame; delim=',', ignorerepeated=true, silencewarnings=true)
    println("Berhasil membaca file $file_path")
catch e
    println("Error: Gagal membaca file $file_path. Pastikan file ada dan formatnya valid.")
    rethrow(e)
end

# Periksa apakah data_latih berhasil dibaca
if data_latih === nothing
    error("Variabel data_latih tidak didefinisikan. Gagal membaca file CSV.")
end

# Cetak nama kolom untuk debugging
println("\nKolom yang tersedia di data_latih: ", names(data_latih))

# Periksa apakah kolom class ada
if !("class" in names(data_latih))
    error("Kolom 'class' tidak ditemukan di data_latih. Kolom yang tersedia: $(names(data_latih))")
end

# Periksa distribusi label awal
println("\nDistribusi label di data_latih:")
try
    println(combine(groupby(data_latih, :class), nrow => :count))
catch e
    println("Error: Gagal menghitung distribusi label. Pastikan kolom 'class' ada di data_latih.")
    rethrow(e)
end

# Peringatan jika semua data memiliki label yang sama
if length(unique(data_latih.class)) == 1
    println("Peringatan: Semua data memiliki label class yang sama. Analisis hubungan mungkin tidak bermakna.")
end

# Tentukan kolom kategorikal berdasarkan nama yang benar
categorical_cols = String[]
for col in ["protocol_type", "service", "flag", "class"]
    if col in names(data_latih)
        push!(categorical_cols, col)
    else
        println("Peringatan: Kolom $col tidak ditemukan di data_latih.")
    end
end

# Konversi kolom ke kategorikal
for col in categorical_cols
    data_latih[!, col] = categorical(data_latih[!, col])
end

# Tangani nilai missing di kolom class
data_latih.class = coalesce.(data_latih.class, "normal")

# Pilih kolom numerik untuk analisis
global numeric_df = nothing
try
    global numeric_df = select(data_latih, Not(categorical_cols))
    println("\nKolom numerik yang dipilih: ", names(numeric_df))
catch e
    println("Error: Gagal memilih kolom numerik. Pastikan kolom kategorikal valid.")
    rethrow(e)
end

# Periksa apakah numeric_df berhasil dibuat
if numeric_df === nothing
    error("Variabel numeric_df tidak didefinisikan.")
end

# Filter hanya kolom bertipe real
real_cols = names(numeric_df)[findall(col -> eltype(numeric_df[!, col]) <: Real, names(numeric_df))]
global numeric_df = select(numeric_df, real_cols)
println("\nKolom bertipe real: ", real_cols)

# Tangani nilai missing di kolom numerik
for col in names(numeric_df)
    if any(ismissing, numeric_df[!, col])
        println("Peringatan: Kolom $col mengandung nilai missing, diganti dengan 0.0")
        numeric_df[!, col] = coalesce.(numeric_df[!, col], 0.0)
    end
end

# Periksa kolom dengan variansi nol
for col in names(numeric_df)
    if var(numeric_df[!, col]) == 0
        println("Peringatan: Kolom $col memiliki variansi nol, akan diabaikan.")
        global numeric_df = select(numeric_df, Not(col))
    end
end

# Hitung matriks korelasi antar atribut numerik
cor_matrix = cor(Matrix(numeric_df))
if any(isnan, cor_matrix) || any(ismissing, cor_matrix)
    println("Peringatan: Matriks korelasi mengandung NaN atau nilai missing. Mengganti NaN dengan 0.0.")
    cor_matrix = replace(cor_matrix, NaN => 0.0)
end
println("\nMatriks korelasi untuk atribut bertipe real:\n", cor_matrix)

# ==================== ANALISIS HUBUNGAN DENGAN CLASS (1a) ====================

# Analisis hubungan antara atribut numerik dan class (kategorikal)
# Menggunakan statistik deskriptif per kelas sebagai pengganti korelasi
println("\nAnalisis hubungan atribut numerik dengan class (normal/anomaly):")
for col in names(numeric_df)
    println("\nStatistik untuk $col berdasarkan class:")
    for class_val in ["normal", "anomaly"]
        subset = data_latih[data_latih.class .== class_val, col]
        if !isempty(subset)
            println("  Class $class_val:")
            println("    Rata-rata: ", mean(subset))
            println("    Median: ", median(subset))
            println("    Standar Deviasi: ", std(subset))
            println("    Minimum: ", minimum(subset))
            println("    Maksimum: ", maximum(subset))
        else
            println("  Class $class_val: Tidak ada data.")
        end
    end
end

# Pilih 3 atribut numerik dengan perbedaan rata-rata terbesar antar kelas
diff_means = DataFrame(attribute = names(numeric_df), diff_mean = zeros(Float64, length(names(numeric_df))))
for (i, col) in enumerate(names(numeric_df))
    normal_subset = data_latih[data_latih.class .== "normal", col]
    anomaly_subset = data_latih[data_latih.class .== "anomaly", col]
    if !isempty(normal_subset) && !isempty(anomaly_subset)
        diff_means.diff_mean[i] = abs(mean(normal_subset) - mean(anomaly_subset))
    else
        diff_means.diff_mean[i] = 0.0
    end
end

# Urutkan berdasarkan perbedaan rata-rata
sort!(diff_means, :diff_mean, rev=true)
println("\nPerbedaan rata-rata atribut numerik antar kelas (normal vs anomaly):")
println(diff_means)

# Pilih 3 atribut dengan perbedaan rata-rata tertinggi
top_3_diff = first(diff_means, 3)
selected_real_attributes = top_3_diff.attribute
println("\n3 atribut bertipe real dengan perbedaan rata-rata tertinggi:")
println(top_3_diff)
println("Atribut yang dipilih: ", selected_real_attributes)

# Simpan DataFrame yang dipilih ke CSV untuk digunakan di file lain
df_selected = select(data_latih, selected_real_attributes)
CSV.write("selected_data.csv", df_selected)
println("DataFrame yang dipilih disimpan sebagai 'selected_data.csv'")

# ==================== ANALISIS STATISTIKA DESKRIPTIF DAN DISTRIBUSI KONTINU (1b) ====================

function descriptive_stats(data, col_name)
    println("\nStatistika Deskriptif untuk kolom: $col_name")
    col_data = data[:, col_name]
    println("  Rata-rata: ", mean(col_data))
    println("  Median: ", median(col_data))
    try
        modes = StatsBase.mode(col_data, 2)  # Coba hitung hingga 2 modus
        println("  Modus: ", modes)
    catch e
        println("  Modus: Tidak dapat dihitung (kemungkinan data kontinu)")
    end
    println("  Standar Deviasi: ", std(col_data))
    println("  Minimum: ", minimum(col_data))
    println("  Maksimum: ", maximum(col_data))
    println("  Kuartil Pertama (Q1): ", quantile(col_data, 0.25))
    println("  Kuartil Ketiga (Q3): ", quantile(col_data, 0.75))
    println("  Skewness: ", skewness(col_data))
    println("  Kurtosis: ", kurtosis(col_data))
end

# Lakukan analisis statistika deskriptif dan distribusi kontinu
for attr in selected_real_attributes
    if attr in names(data_latih)
        # Analisis statistika deskriptif
        descriptive_stats(data_latih, attr)
        
        # Pasang distribusi Normal
        col_data = data_latih[:, attr]
        try
            dist = fit(Normal, col_data)
            println("\nDistribusi Normal yang dipasang untuk $attr: μ = ", mean(dist), ", σ = ", std(dist))
            
            # Plot histogram dengan PDF distribusi Normal
            p = histogram(col_data, bins=30, normalize=true, title="Distribusi $attr", xlabel=attr, ylabel="Densitas", legend=:topright, alpha=0.7)
            x_range = range(minimum(col_data), maximum(col_data), length=100)
            plot!(x_range, pdf.(dist, x_range), label="PDF Normal Terpasang", linewidth=2)
            savefig("distribusi_$(attr).png")
            println("Plot distribusi untuk $attr disimpan sebagai distribusi_$(attr).png")
        catch e
            println("Peringatan: Gagal memasang distribusi Normal untuk $attr: ", e)
        end
    else
        println("Peringatan: Atribut '$attr' tidak ditemukan di data_latih untuk analisis.")
    end
end