FROM node:18

WORKDIR /app

# copy package ก่อนเพื่อ cache layer
COPY package*.json ./

RUN npm install

# copy prisma schema ก่อน
COPY prisma ./prisma

# generate prisma client
RUN npx prisma generate

# copy source code ที่เหลือทั้งหมด
COPY . .

EXPOSE 3000

CMD ["npm", "start"]
