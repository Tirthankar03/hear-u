// utils/cloudinary.ts
import cloudinary from "cloudinary";
import { Readable } from "stream";

cloudinary.v2.config({
  cloud_name: process.env["CLOUDINARY_CLOUD_NAME"],
  api_key: process.env["CLOUDINARY_API_KEY"],
  api_secret: process.env["CLOUDINARY_API_SECRET"],
});

// Upload audio files
export const uploadAudioToCloudinary = (buffer: Buffer, originalName: string) => {
  return new Promise((resolve, reject) => {
    const timestamp = Date.now();
    const uniqueFilename = `${timestamp}_${originalName.replace(/\s+/g, "_")}`;

    const uploadStream = cloudinary.v2.uploader.upload_stream(
      {
        folder: "audios",
        public_id: uniqueFilename,
        resource_type: "video", // Use video for audio files in Cloudinary
      },
      (error, result) => {
        console.log("error>>>", error)
        console.log("result>>>", result)
        if (error) reject(error);

        else resolve(result);
      }
    );

    

    const readableStream = Readable.from(buffer);
    console.log("readableStream>>>", readableStream)


    readableStream.pipe(uploadStream);
  });
};

// Upload images
export const uploadImageToCloudinary = (buffer: Buffer, originalName: string) => {
  return new Promise((resolve, reject) => {
    const timestamp = Date.now();
    const uniqueFilename = `${timestamp}_${originalName.replace(/\s+/g, "_")}`;

    const uploadStream = cloudinary.v2.uploader.upload_stream(
      {
        folder: "articles",
        public_id: uniqueFilename,
      },
      (error, result) => {
        if (error) reject(error);
        else resolve(result);
      }
    );

    const readableStream = Readable.from(buffer);
    readableStream.pipe(uploadStream);
  });
};

// Delete resource from Cloudinary
export const deleteFromCloudinary = async (url: string, resource_type: "image" | "video" = "image") => {
  const publicId = url.split("/").pop()?.split(".")[0];
  if (publicId) {
    await cloudinary.v2.uploader.destroy(`${resource_type === "image" ? "articles" : "audios"}/${publicId}`, {
      resource_type
    });
  }
};