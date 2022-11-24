FROM node:latest

RUN curl -f https://get.pnpm.io/v6.16.js | node - add --global pnpm
RUN mkdir app

WORKDIR /app

COPY package.json yarn.lock tsconfig.json ./
COPY dist ./dist

RUN yarn install --immutable

CMD ["yarn", "start"]