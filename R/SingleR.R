library(SingleR)
library(Seurat)
library(reshape2)
library(pheatmap)
library(kableExtra)
source("../R/Seurat_functions.R")
source("../R/SingleR_functions.R")

#====== 2.1 Create Singler Object  ==========================================
lname1 = load(file = "data/MouseSkin_alignment.Rda");lname1
lname2 = load(file='../SingleR/data/ref_Mouse.RData');lname2
ref_immgen_mouse.rnaseq$name
length(ref_immgen_mouse.rnaseq$types)
length(unique(ref_immgen_mouse.rnaseq$types))
length(unique(ref_immgen_mouse.rnaseq$main_types))

#pca
DimPlot(object = MouseSkin, reduction.use = "tsne", no.legend = TRUE,
        do.return = TRUE,vector.friendly = F, pt.size = 1,
        do.label = TRUE,label.size = 8, group.by = "ident") + 
        ggtitle("Cluster ID") + 
        theme(plot.title = element_text(hjust = 0.5))
singler = CreateSinglerObject(as.matrix(MouseSkin@data), annot = NULL, 
                              project.name=MouseSkin@project.name,
                              min.genes = 500,technology = "10X", species = "Mouse",
                              ref.list = list(ref_immgen_mouse.rnaseq), normalize.gene.length = F, 
                              variable.genes = "de",
                              fine.tune = F, do.signatures = F, clusters = NULL)
GC()
singler$meta.data$orig.ident = MouseSkin@meta.data$orig.ident # the original identities, if not supplied in 'annot'
singler$meta.data$xy = MouseSkin@dr$tsne@cell.embeddings # the tSNE coordinates
singler$meta.data$clusters = MouseSkin@ident # the Seurat clusters (if 'clusters' not provided)
save(singler,file="./output/singler_MouseSkin.RData")
#====== 3.2 SingleR specifications ==========================================
# Step 1: Spearman coefficient
lnames = load(file = "./output/singler_MouseSkin.RData")
lnames
singler$seurat = MouseSkin # (optional)
SingleR.DrawScatter(sc_data = singler$seurat@data,cell_id = 10, 
                    ref = immgen, sample_id = 232)

# Step 2: Multiple correlation coefficients per cell types are aggregated 
# to provide a single value per cell type per single-cell. 
# In the examples below we use the 80% percentile of correlation values.
# for visualization purposes we only present a subset of cell types (defined in labels.use)
out = SingleR.DrawBoxPlot(sc_data = singler$seurat@data,cell_id = 10, 
                          ref = immgen,main_types = T,
                          labels.use=c('B cells','T cells','DC','Macrophages','Monocytes','NK cells',
                                       'Mast cells','Neutrophils','Fibroblasts','Endothelial cells'))
print(out$plot)
SingleR.DrawHeatmap(singler$singler[[1]]$SingleR.single.main, top.n = Inf,
                    clusters = singler$meta.data$orig.ident)
#Or by all cell types (showing the top 50 cell types):
SingleR.DrawHeatmap(singler$singler[[1]]$SingleR.single, top.n = 50,
                    clusters = singler$meta.data$orig.ident)
SingleR.DrawHeatmap(singler$singler[[1]]$SingleR.single.main,top.n = 50,
                    normalize = F,clusters = singler$meta.data$orig.ident)
#Next, we can use the fine-tuned labels to color the t-SNE plot:

out = SingleR.PlotTsne.1(singler$singler[[1]]$SingleR.single,
                         singler$meta.data$xy,do.label=T,
                         do.letters = F,labels = singler$singler[[1]]$SingleR.single$labels,
                         label.size = 2, dot.size = 2 ,do.legend = F,alpha = 1,
                         label.repel = T,force=2)
out+  ggtitle("Supervised sub-cell type labeling by immgen")+
        theme(text = element_text(size=20),
              plot.title = element_text(hjust = 0.5,size = 18, face = "bold"))
# main types-------
out = SingleR.PlotTsne.1(singler$singler[[1]]$SingleR.single.main,
                         singler$meta.data$xy,do.label=T,
                         do.letters = F,labels = singler$singler[[1]]$SingleR.single.main$labels,
                         label.size = 5, dot.size = 2 ,do.legend = F,alpha = 1,
                         label.repel = T,force=2)
out +  ggtitle("Supervised cell type labeling by immgen and RNA-seq")+
        theme(text = element_text(size=20),
              plot.title = element_text(hjust = 0.5,size = 18, face = "bold"))

g <- ggplot_build(out$p)

# split singleR plot
output <- SplitSingleR.PlotTsne(singler = singler, split.by = "conditions",main=T,
                                select.plots =c(2,1),
                                return.plots= T,do.label=T,do.legend = F,alpha = 1,
                                label.repel = T, force=2)
plot_grid(output[[1]], output[[2]])
#Finally, we can also view the labeling as a table compared to the original identities:

# cell number
kable(table(singler$singler[[1]]$SingleR.single.main$labels,
            singler$meta.data$orig.ident)) %>%
        kable_styling()
# cell percentage
prop.table(x = table(singler$singler[[1]]$SingleR.single.main$labels,
                     MouseSkin@meta.data$orig.ident),margin = 2) %>%
        kable()  %>% kable_styling()
# total cell number
table(singler$meta.data$orig.ident) %>% t() %>% kable() %>% kable_styling()

# Rename ident
table(names(MouseSkin@ident) == rownames(singler$singler[[1]]$SingleR.single.main$labels))

ident.use <- as.factor(as.character(singler$singler[[1]]$SingleR.single.main$labels))
names(ident.use) = rownames(singler$singler[[1]]$SingleR.single.main$labels)
MouseSkin@ident <- ident.use

TSNEPlot(object = MouseSkin,do.label = F, group.by = "ident", 
         do.return = TRUE, no.legend = F,
         pt.size = 1,label.size = 8 )+
        ggtitle("Supervised cell type labeling by GSE43717")+
        theme(text = element_text(size=20),							
              plot.title = element_text(hjust = 0.5))

save(MouseSkin, file = "data/MouseSkin_suplabel_GSE43717.Rda")