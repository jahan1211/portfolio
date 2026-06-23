const fs = require('fs');
const path = require('path');

const contentDirs = {
  uiux: path.join(__dirname, 'uiux'),
  mockups: path.join(__dirname, 'Mockups'),
  posters: path.join(__dirname, 'Posters & Creatives'),
  videos: path.join(__dirname, 'Vedio Animation'),
};

const manifestPath = path.join(__dirname, 'manifest.json');

// Helper to check if file is an image
const isImage = (fileName) => {
  const ext = path.extname(fileName).toLowerCase();
  return ['.png', '.jpg', '.jpeg', '.webp', '.gif', '.tiff'].includes(ext);
};

// Helper to check if file is a video
const isVideo = (fileName) => {
  const ext = path.extname(fileName).toLowerCase();
  return ['.mp4', '.webm', '.ogg', '.mov'].includes(ext);
};

// Format names nicely (e.g., "01_splash_screen.png" -> "Splash Screen")
const formatName = (fileName) => {
  let name = path.basename(fileName, path.extname(fileName));
  // Remove leading numbers/ordering (e.g., "01_", "1.")
  name = name.replace(/^\d+[\s_-]*/, '');
  // Replace underscores and hyphens with spaces
  name = name.replace(/[\s_-]+/g, ' ');
  // Capitalize words
  return name.replace(/\b\w/g, (c) => c.toUpperCase());
};

const generateManifest = () => {
  console.log('Generating manifest.json...');

  const manifest = {
    uiux: [],
    mockups: [],
    posters: [],
    videos: [],
  };

  // 1. Process UI/UX Folders
  if (fs.existsSync(contentDirs.uiux)) {
    const folders = fs.readdirSync(contentDirs.uiux);
    folders.forEach((folder) => {
      const folderPath = path.join(contentDirs.uiux, folder);
      if (fs.statSync(folderPath).isDirectory()) {
        const files = fs.readdirSync(folderPath);
        const imageFiles = files.filter(isImage).sort();
        
        let metadata = {
          title: `${folder} UX Case Study`,
          tag: 'UI/UX Design',
          desc: 'A premium user interface and experience design concept showcasing user-centered workflows and modern design guidelines.',
          figmaUrl: '',
          behanceUrl: '',
        };

        // Load project.json if exists
        const metaPath = path.join(folderPath, 'project.json');
        if (fs.existsSync(metaPath)) {
          try {
            const fileData = fs.readFileSync(metaPath, 'utf8');
            const customMeta = JSON.parse(fileData);
            metadata = { ...metadata, ...customMeta };
          } catch (e) {
            console.error(`Error parsing metadata in ${folder}:`, e.message);
          }
        }

        const projId = folder.toLowerCase().replace(/[^a-z0-9]+/g, '-');

        // Auto-detect mockup image
        let mockupPath = '';
        
        // 1. Search in parent uiux folder for files matching [projId]-mockup
        const parentFiles = fs.readdirSync(contentDirs.uiux);
        const cleanId = projId.replace(/[\s_-]+/g, '[\\s_-]?');
        const mockupRegex = new RegExp(`^${cleanId}[\\s_-]?mockup\\.(png|jpg|jpeg|webp)$`, 'i');
        const matchedParentFile = parentFiles.find(file => isImage(file) && mockupRegex.test(file));
        
        if (matchedParentFile) {
          mockupPath = `uiux/${matchedParentFile}`;
        } else {
          // 2. Search inside the project folder for any file containing 'mockup', 'cover', or 'hero'
          const localMockupFile = imageFiles.find(file => {
            const lower = file.toLowerCase();
            return lower.includes('mockup') || lower.includes('cover') || lower.includes('hero');
          });
          
          if (localMockupFile) {
            mockupPath = `uiux/${folder}/${localMockupFile}`;
          } else {
            // 3. Fallback to the first image inside the folder
            if (imageFiles.length > 0) {
              mockupPath = `uiux/${folder}/${imageFiles[0]}`;
            }
          }
        }

        const project = {
          id: projId,
          folderName: folder,
          title: metadata.title,
          tag: metadata.tag,
          desc: metadata.desc,
          figmaUrl: metadata.figmaUrl,
          behanceUrl: metadata.behanceUrl,
          mockup: mockupPath,
          techStack: metadata.techStack || ["UI/UX Design", "Figma", "Prototyping"],
          modules: imageFiles.map((file) => {
            const customModule = (metadata.modules || []).find(m => m.file === file);
            return {
              name: customModule ? customModule.name : formatName(file),
              desc: customModule ? customModule.desc : `Interface representation of ${formatName(file)}.`,
              type: 'image',
              url: `uiux/${folder}/${file}`
            };
          }),
          directory: imageFiles.map((file) => ({
            name: formatName(file),
            type: 'image',
            url: `uiux/${folder}/${file}`
          }))
        };

        manifest.uiux.push(project);
      }
    });
  }

  // 2. Process Mockups
  if (fs.existsSync(contentDirs.mockups)) {
    const files = fs.readdirSync(contentDirs.mockups);
    files.filter(isImage).forEach((file) => {
      manifest.mockups.push({
        name: formatName(file),
        url: `Mockups/${file}`
      });
    });
  }

  // 3. Process Posters & Creatives
  if (fs.existsSync(contentDirs.posters)) {
    const files = fs.readdirSync(contentDirs.posters);
    files.filter(isImage).forEach((file) => {
      // Exclude portrait placeholder images in root/posters that aren't designs
      if (file.toLowerCase().startsWith('nusrat') && !file.toLowerCase().includes('design')) {
        return;
      }
      manifest.posters.push({
        name: formatName(file),
        url: `Posters & Creatives/${file}`
      });
    });
  }

  // 4. Process Videos (Vedio Animation)
  if (fs.existsSync(contentDirs.videos)) {
    const files = fs.readdirSync(contentDirs.videos);
    
    // Support thumbnails if they match the video name
    const videos = files.filter(isVideo);
    const images = files.filter(isImage);

    videos.forEach((videoFile) => {
      const videoBaseName = path.basename(videoFile, path.extname(videoFile));
      // Find matching thumbnail image (starts with or contains video base name)
      const matchingImg = images.find(img => {
        const imgBase = path.basename(img, path.extname(img)).toLowerCase();
        const vBase = videoBaseName.toLowerCase();
        return imgBase === vBase || imgBase.startsWith(vBase) || imgBase.includes(vBase);
      });
      
      manifest.videos.push({
        name: formatName(videoFile),
        url: `Vedio Animation/${videoFile}`,
        thumbnail: matchingImg ? `Vedio Animation/${matchingImg}` : ''
      });
    });
  }

  // Write manifest JSON
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2), 'utf8');

  // Write manifest JS (CORS-free local filesystem loading)
  const manifestJsPath = path.join(__dirname, 'manifest.js');
  fs.writeFileSync(manifestJsPath, `window.portfolioManifest = ${JSON.stringify(manifest, null, 2)};`, 'utf8');

  console.log(`Success! manifest.json and manifest.js created with:`);
  console.log(`- ${manifest.uiux.length} UI/UX Projects`);
  console.log(`- ${manifest.mockups.length} Mockups`);
  console.log(`- ${manifest.posters.length} Posters`);
  console.log(`- ${manifest.videos.length} Videos`);
};

generateManifest();
