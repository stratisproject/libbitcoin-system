/**
 * Copyright (c) 2011-2019 libbitcoin developers (see AUTHORS)
 *
 * This file is part of libbitcoin.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#include <bitcoin/system/math/hash.hpp>

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <errno.h>
#include <new>
#include <stdexcept>
#include "../math/external/crypto_scrypt.h"
#include "../math/external/hmac_sha256.h"
#include "../math/external/hmac_sha512.h"
#include "../math/external/pbkdf2_sha256.h"
#include "../math/external/pkcs5_pbkdf2.h"
#include "../math/external/ripemd160.h"
#include "../math/external/sha1.h"
#include "../math/external/sha256.h"
#include "../math/external/sha512.h"

namespace libbitcoin {
namespace system {

hash_digest bitcoin_hash(const data_slice& data)
{
    return sha256_hash(sha256_hash(data));
}

hash_digest scrypt_hash(const data_slice& data)
{
    return scrypt<hash_size>(data, data, 1024u, 1u, 1u);
}

short_hash bitcoin_short_hash(const data_slice& data)
{
    return ripemd160_hash(sha256_hash(data));
}

short_hash ripemd160_hash(const data_slice& data)
{
    short_hash hash;
    RMD160(data.data(), data.size(), hash.data());
    return hash;
}

data_chunk ripemd160_hash_chunk(const data_slice& data)
{
    data_chunk hash(short_hash_size);
    RMD160(data.data(), data.size(), hash.data());
    return hash;
}

short_hash sha1_hash(const data_slice& data)
{
    short_hash hash;
    SHA1_(data.data(), data.size(), hash.data());
    return hash;
}

data_chunk sha1_hash_chunk(const data_slice& data)
{
    data_chunk hash(short_hash_size);
    SHA1_(data.data(), data.size(), hash.data());
    return hash;
}

hash_digest sha256_hash(const data_slice& data)
{
    hash_digest hash;
    SHA256_(data.data(), data.size(), hash.data());
    return hash;
}

data_chunk sha256_hash_chunk(const data_slice& data)
{
    data_chunk hash(hash_size);
    SHA256_(data.data(), data.size(), hash.data());
    return hash;
}

hash_digest sha256_hash(const data_slice& first, const data_slice& second)
{
    hash_digest hash;
    SHA256CTX context;
    internalSHA256Init(&context);
    internalSHA256Update(&context, first.data(), first.size());
    internalSHA256Update(&context, second.data(), second.size());
    internalSHA256Final(&context, hash.data());
    return hash;
}

hash_digest hmac_sha256_hash(const data_slice& data, const data_slice& key)
{
    hash_digest hash;
    HMACSHA256(data.data(), data.size(), key.data(), key.size(), hash.data());
    return hash;
}

long_hash sha512_hash(const data_slice& data)
{
    long_hash hash;
    SHA512_(data.data(), data.size(), hash.data());
    return hash;
}

long_hash hmac_sha512_hash(const data_slice& data, const data_slice& key)
{
    long_hash hash;
    HMACSHA512(data.data(), data.size(), key.data(), key.size(), hash.data());
    return hash;
}

long_hash pkcs5_pbkdf2_hmac_sha512(const data_slice& passphrase,
    const data_slice& salt, size_t iterations)
{
    long_hash hash;
    const auto result = pkcs5_pbkdf2(passphrase.data(), passphrase.size(),
        salt.data(), salt.size(), hash.data(), hash.size(), iterations);

    if (result != 0)
        throw std::bad_alloc();

    return hash;
}

data_chunk pbkdf2_hmac_sha256(const data_slice& passphrase,
    const data_slice& salt, size_t iterations, size_t length)
{
    data_chunk output(length);
    pbkdf2_sha256(passphrase.data(), passphrase.size(), salt.data(),
        salt.size(), iterations, output.data(), length);
    return output;
}

static void handle_script_result(int result)
{
    if (result == 0)
        return;

    switch (errno)
    {
        case EFBIG:
            throw std::length_error("scrypt parameter too large");
        case EINVAL:
            throw std::runtime_error("scrypt invalid argument");
        case ENOMEM:
            throw std::length_error("scrypt address space");
        default:
            throw std::bad_alloc();
    }
}

data_chunk scrypt(const data_slice& data, const data_slice& salt, uint64_t N,
    uint32_t p, uint32_t r, size_t length)
{
    data_chunk output(length);
    const auto result = crypto_scrypt(data.data(), data.size(), salt.data(),
        salt.size(), N, r, p, output.data(), output.size());
    handle_script_result(result);
    return output;
}

} // namespace system
} // namespace libbitcoin
